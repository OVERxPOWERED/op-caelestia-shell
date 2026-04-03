#include "lazylistview.hpp"

#include <algorithm>
#include <qpropertyanimation.h>
#include <qtimer.h>

namespace caelestia::components {

// --- LazyListViewAttached ---

LazyListViewAttached::LazyListViewAttached(QObject* parent)
    : QObject(parent) {}

qreal LazyListViewAttached::preferredHeight() const {
    return m_preferredHeight;
}

void LazyListViewAttached::setPreferredHeight(qreal height) {
    if (qFuzzyCompare(m_preferredHeight, height))
        return;
    m_preferredHeight = height;
    emit preferredHeightChanged();
}

qreal LazyListViewAttached::visibleHeight() const {
    return m_visibleHeight;
}

void LazyListViewAttached::setVisibleHeight(qreal height) {
    if (qFuzzyCompare(m_visibleHeight, height))
        return;
    m_visibleHeight = height;
    emit visibleHeightChanged();
}

bool LazyListViewAttached::adding() const {
    return m_adding;
}

void LazyListViewAttached::setAdding(bool adding) {
    if (m_adding == adding)
        return;
    m_adding = adding;
    emit addingChanged();
}

bool LazyListViewAttached::removing() const {
    return m_removing;
}

void LazyListViewAttached::setRemoving(bool removing) {
    if (m_removing == removing)
        return;
    m_removing = removing;
    emit removingChanged();
}

// --- LazyListView ---

LazyListView::LazyListView(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents, false);
}

LazyListViewAttached* LazyListView::qmlAttachedProperties(QObject* object) {
    return new LazyListViewAttached(object);
}

LazyListView::~LazyListView() {
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
}

// --- Model & Delegate ---

QAbstractItemModel* LazyListView::model() const {
    return m_model;
}

void LazyListView::setModel(QAbstractItemModel* model) {
    if (m_model == model)
        return;

    if (m_model)
        disconnectModel();

    m_model = model;

    if (m_model)
        connectModel();

    resetContent();
    emit modelChanged();
}

QQmlComponent* LazyListView::delegate() const {
    return m_delegate;
}

void LazyListView::setDelegate(QQmlComponent* delegate) {
    if (m_delegate == delegate)
        return;

    m_delegate = delegate;
    resetContent();
    emit delegateChanged();
}

// --- Layout ---

qreal LazyListView::spacing() const {
    return m_spacing;
}

void LazyListView::setSpacing(qreal spacing) {
    if (qFuzzyCompare(m_spacing, spacing))
        return;
    m_spacing = spacing;
    emit spacingChanged();
    polish();
}

qreal LazyListView::contentHeight() const {
    return m_contentHeight;
}

qreal LazyListView::contentY() const {
    return m_contentY;
}

void LazyListView::setContentY(qreal contentY) {
    if (qFuzzyCompare(m_contentY, contentY))
        return;
    m_contentY = contentY;
    emit contentYChanged();
    polish();
}

// --- Viewport ---

QRectF LazyListView::viewport() const {
    return m_viewport;
}

void LazyListView::setViewport(const QRectF& viewport) {
    if (m_viewport == viewport)
        return;
    m_viewport = viewport;
    emit viewportChanged();
    if (m_useCustomViewport)
        polish();
}

bool LazyListView::useCustomViewport() const {
    return m_useCustomViewport;
}

void LazyListView::setUseCustomViewport(bool use) {
    if (m_useCustomViewport == use)
        return;
    m_useCustomViewport = use;
    emit useCustomViewportChanged();
    polish();
}

qreal LazyListView::cacheBuffer() const {
    return m_cacheBuffer;
}

void LazyListView::setCacheBuffer(qreal buffer) {
    if (qFuzzyCompare(m_cacheBuffer, buffer))
        return;
    m_cacheBuffer = buffer;
    emit cacheBufferChanged();
    polish();
}

// --- Sizing ---

qreal LazyListView::estimatedHeight() const {
    return m_estimatedHeight;
}

void LazyListView::setEstimatedHeight(qreal height) {
    if (qFuzzyCompare(m_estimatedHeight, height))
        return;
    m_estimatedHeight = height;
    emit estimatedHeightChanged();
    polish();
}

qreal LazyListView::effectiveEstimatedHeight() const {
    if (m_estimatedHeight >= 0)
        return m_estimatedHeight;
    if (m_knownHeightCount > 0)
        return m_knownHeightSum / m_knownHeightCount;
    return 40;
}

void LazyListView::trackHeight(qreal height) {
    m_knownHeightSum += height;
    ++m_knownHeightCount;
}

void LazyListView::untrackHeight(qreal height) {
    m_knownHeightSum -= height;
    --m_knownHeightCount;
}

qreal LazyListView::delegateHeight(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = qobject_cast<LazyListViewAttached*>(
        qmlAttachedPropertiesObject<LazyListView>(item, false));
    if (attached && attached->preferredHeight() >= 0)
        return attached->preferredHeight();

    return item->implicitHeight();
}

qreal LazyListView::delegateVisibleHeight(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = qobject_cast<LazyListViewAttached*>(
        qmlAttachedPropertiesObject<LazyListView>(item, false));
    if (attached) {
        if (attached->visibleHeight() >= 0)
            return attached->visibleHeight();
        if (attached->preferredHeight() >= 0)
            return attached->preferredHeight();
    }

    return item->implicitHeight();
}

// --- Add Animation ---

int LazyListView::addDuration() const {
    return m_addDuration;
}

void LazyListView::setAddDuration(int duration) {
    if (m_addDuration == duration)
        return;
    m_addDuration = duration;
    emit addDurationChanged();
}

QEasingCurve LazyListView::addCurve() const {
    return m_addCurve;
}

void LazyListView::setAddCurve(const QEasingCurve& curve) {
    if (m_addCurve == curve)
        return;
    m_addCurve = curve;
    emit addCurveChanged();
}

qreal LazyListView::addFromOpacity() const {
    return m_addFromOpacity;
}

void LazyListView::setAddFromOpacity(qreal opacity) {
    if (qFuzzyCompare(m_addFromOpacity, opacity))
        return;
    m_addFromOpacity = opacity;
    emit addFromOpacityChanged();
}

qreal LazyListView::addFromScale() const {
    return m_addFromScale;
}

void LazyListView::setAddFromScale(qreal scale) {
    if (qFuzzyCompare(m_addFromScale, scale))
        return;
    m_addFromScale = scale;
    emit addFromScaleChanged();
}

// --- Remove Animation ---

int LazyListView::removeDuration() const {
    return m_removeDuration;
}

void LazyListView::setRemoveDuration(int duration) {
    if (m_removeDuration == duration)
        return;
    m_removeDuration = duration;
    emit removeDurationChanged();
}

QEasingCurve LazyListView::removeCurve() const {
    return m_removeCurve;
}

void LazyListView::setRemoveCurve(const QEasingCurve& curve) {
    if (m_removeCurve == curve)
        return;
    m_removeCurve = curve;
    emit removeCurveChanged();
}

qreal LazyListView::removeToOpacity() const {
    return m_removeToOpacity;
}

void LazyListView::setRemoveToOpacity(qreal opacity) {
    if (qFuzzyCompare(m_removeToOpacity, opacity))
        return;
    m_removeToOpacity = opacity;
    emit removeToOpacityChanged();
}

qreal LazyListView::removeToScale() const {
    return m_removeToScale;
}

void LazyListView::setRemoveToScale(qreal scale) {
    if (qFuzzyCompare(m_removeToScale, scale))
        return;
    m_removeToScale = scale;
    emit removeToScaleChanged();
}

// --- Move Animation ---

int LazyListView::moveDuration() const {
    return m_moveDuration;
}

void LazyListView::setMoveDuration(int duration) {
    if (m_moveDuration == duration)
        return;
    m_moveDuration = duration;
    emit moveDurationChanged();
}

QEasingCurve LazyListView::moveCurve() const {
    return m_moveCurve;
}

void LazyListView::setMoveCurve(const QEasingCurve& curve) {
    if (m_moveCurve == curve)
        return;
    m_moveCurve = curve;
    emit moveCurveChanged();
}

// --- State ---

int LazyListView::count() const {
    return m_model ? m_model->rowCount() : 0;
}

bool LazyListView::settled() const {
    return m_activeAnimations == 0;
}

// --- QQuickItem Overrides ---

void LazyListView::componentComplete() {
    QQuickItem::componentComplete();
    m_componentComplete = true;
    resetContent();
}

void LazyListView::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (!m_componentComplete)
        return;

    if (!qFuzzyCompare(newGeometry.width(), oldGeometry.width())) {
        for (auto& entry : m_delegates) {
            if (entry.item)
                entry.item->setWidth(newGeometry.width());
        }
    }

    polish();
}

void LazyListView::updatePolish() {
    if (!m_componentComplete || !m_model || !m_delegate)
        return;

    relayout();
    syncDelegates();

    // Position delegates — QML Behavior on y handles the animation
    for (auto& entry : m_delegates) {
        if (!entry.item || entry.pendingRemoval)
            continue;

        const int idx = entry.modelIndex;
        if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
            continue;

        if (m_layout[idx].heightKnown && qFuzzyIsNull(m_layout[idx].height))
            continue;

        // Use setProperty to go through the QML property system,
        // which triggers Behaviors (setY bypasses them).
        entry.item->setProperty("y", m_layout[idx].targetY - m_contentY);
    }
}

// --- Layout Engine ---

void LazyListView::relayout() {
    // Layout positioning uses preferredHeight (final/non-animated)
    qreal y = 0;
    for (auto& record : m_layout) {
        record.targetY = y;
        y += (record.heightKnown ? record.height : effectiveEstimatedHeight()) + m_spacing;
    }

    // Content height tracks actual visible heights so scrolling follows animations
    qreal visY = 0;
    for (int i = 0; i < static_cast<int>(m_layout.size()); ++i) {
        qreal h;
        if (m_delegates.contains(i) && m_delegates[i].item)
            h = delegateVisibleHeight(m_delegates[i].item);
        else
            h = m_layout[i].heightKnown ? m_layout[i].height : effectiveEstimatedHeight();
        visY += h + m_spacing;
    }
    qreal maxBottom = m_layout.isEmpty() ? 0 : visY - m_spacing;

    // Account for dying delegates still visually present
    for (const auto& dying : m_dyingDelegates) {
        if (dying.item)
            maxBottom = std::max(maxBottom, dying.item->y() + delegateVisibleHeight(dying.item));
    }

    if (!qFuzzyCompare(m_contentHeight, maxBottom)) {
        m_contentHeight = maxBottom;
        emit contentHeightChanged();
    }
}

QRectF LazyListView::effectiveViewport() const {
    if (m_useCustomViewport)
        return m_viewport.adjusted(0, -m_cacheBuffer, 0, m_cacheBuffer);

    return QRectF(0, m_contentY - m_cacheBuffer, width(), height() + 2 * m_cacheBuffer);
}

std::pair<int, int> LazyListView::computeVisibleRange() const {
    if (m_layout.isEmpty())
        return { -1, -1 };

    const auto vp = effectiveViewport();
    const qreal vpTop = vp.y();
    const qreal vpBottom = vp.y() + vp.height();

    // Binary search for first visible item
    int lo = 0;
    int hi = static_cast<int>(m_layout.size()) - 1;
    int first = static_cast<int>(m_layout.size());

    while (lo <= hi) {
        const int mid = lo + (hi - lo) / 2;
        const auto& record = m_layout[mid];
        const qreal itemBottom = record.targetY + (record.heightKnown ? record.height : effectiveEstimatedHeight());

        if (itemBottom >= vpTop) {
            first = mid;
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }

    if (first >= static_cast<int>(m_layout.size()))
        return { -1, -1 };

    // Linear scan for last visible item
    int last = first;
    for (int i = first; i < static_cast<int>(m_layout.size()); ++i) {
        if (m_layout[i].targetY > vpBottom)
            break;
        last = i;
    }

    return { first, last };
}

// --- Delegate Lifecycle ---

void LazyListView::syncDelegates() {
    const auto [first, last] = computeVisibleRange();

    // Collect indices that should be alive
    QSet<int> visibleIndices;
    if (first >= 0) {
        for (int i = first; i <= last; ++i)
            visibleIndices.insert(i);
    }

    // Destroy delegates outside visible range (if not animating)
    QList<int> toRemove;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        if (!visibleIndices.contains(it.key()) && !it->animation) {
            toRemove.append(it.key());
        }
    }
    for (int idx : toRemove) {
        auto entry = m_delegates.take(idx);
        destroyDelegate(entry);
    }

    // Create delegates for newly visible indices
    if (first >= 0) {
        for (int i = first; i <= last; ++i) {
            if (m_delegates.contains(i))
                continue;

            auto entry = createDelegate(i);
            if (entry.item) {
                // Measure height (prefer attached preferredHeight, fall back to implicitHeight)
                const qreal h = delegateHeight(entry.item);
                if (h > 0 && !m_layout[i].heightKnown) {
                    m_layout[i].height = h;
                    m_layout[i].heightKnown = true;
                    trackHeight(h);
                }
                // Position immediately so it doesn't flash at y=0
                entry.item->setY(m_layout[i].targetY - m_contentY);
                m_delegates.insert(i, std::move(entry));
            }
        }
    }
}

LazyListView::DelegateEntry LazyListView::createDelegate(int modelIndex) {
    DelegateEntry entry;
    entry.modelIndex = modelIndex;

    if (!m_delegate || !m_model)
        return entry;

    const auto roleNames = m_model->roleNames();
    const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();

    // Use the delegate component's creation context so the delegate
    // can access ids and properties from the scope where it was defined.
    auto* compContext = m_delegate->creationContext();
    auto* parentContext = compContext ? compContext : qmlContext(this);
    if (!parentContext)
        return entry;

    entry.context = new QQmlContext(parentContext, this);

    // Build property map for both context properties and initial properties
    const auto index = m_model->index(modelIndex, 0);
    QVariantMap initialProps;

    bool hasModelData = false;
    for (auto it = roleNames.constBegin(); it != roleNames.constEnd(); ++it) {
        const auto name = QString::fromUtf8(it.value());
        const auto value = m_model->data(index, it.key());
        entry.context->setContextProperty(name, value);
        initialProps.insert(name, value);
        if (name == QStringLiteral("modelData"))
            hasModelData = true;
    }
    entry.context->setContextProperty(QStringLiteral("index"), modelIndex);
    initialProps.insert(QStringLiteral("index"), modelIndex);

    // Provide modelData for single-role models or if not already provided by role names
    if (!hasModelData) {
        const auto value = m_model->data(index, role);
        entry.context->setContextProperty(QStringLiteral("modelData"), value);
        initialProps.insert(QStringLiteral("modelData"), value);
    }

    auto* obj = m_delegate->beginCreate(entry.context);
    entry.item = qobject_cast<QQuickItem*>(obj);

    if (!entry.item) {
        delete obj;
        delete entry.context;
        entry.context = nullptr;
        return entry;
    }

    // Set initial properties to satisfy required property declarations
    m_delegate->setInitialProperties(entry.item, initialProps);

    entry.item->setParentItem(this);
    entry.item->setWidth(width());

    // Set adding = true before completeCreate so bindings see it during initial evaluation.
    // Cleared after creation so the transition from true→false triggers QML Behaviors.
    auto* addingAttached = qobject_cast<LazyListViewAttached*>(
        qmlAttachedPropertiesObject<LazyListView>(entry.item, true));
    if (addingAttached)
        addingAttached->setAdding(true);

    m_delegate->completeCreate();

    if (addingAttached)
        addingAttached->setAdding(false);

    // Shared height-change handler — captures item pointer instead of index
    // so it remains valid after model inserts/removes/moves shift indices.
    auto onHeightChanged = [this, item = entry.item] {
        // Find the delegate entry by item pointer
        for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
            if (it->item != item)
                continue;
            const int idx = it.key();
            const qreal h = delegateHeight(item);
            if (idx < static_cast<int>(m_layout.size()) && !qFuzzyCompare(m_layout[idx].height, h)) {
                const qreal oldH = m_layout[idx].height;
                const bool wasKnown = m_layout[idx].heightKnown;
                m_layout[idx].height = h;
                m_layout[idx].heightKnown = true;
                if (wasKnown)
                    untrackHeight(oldH);
                trackHeight(h);
                polish();
            }
            return;
        }
    };

    // Watch implicitHeight as fallback
    connect(entry.item, &QQuickItem::implicitHeightChanged, this, onHeightChanged);

    // Watch attached properties if the delegate uses them
    auto* attached = qobject_cast<LazyListViewAttached*>(
        qmlAttachedPropertiesObject<LazyListView>(entry.item, false));
    if (attached) {
        entry.attachedConnection = connect(attached, &LazyListViewAttached::preferredHeightChanged,
                                           this, onHeightChanged);
        connect(attached, &LazyListViewAttached::visibleHeightChanged,
                this, [this] { polish(); });
    }

    return entry;
}

void LazyListView::destroyDelegate(DelegateEntry& entry) {
    if (entry.animation) {
        // Disconnect before stopping to prevent re-entrant onAnimationFinished
        disconnect(entry.animation, &QAbstractAnimation::finished,
                   this, &LazyListView::onAnimationFinished);
        entry.animation->stop();
        entry.animation = nullptr;
        --m_activeAnimations;
        if (m_activeAnimations == 0)
            emit settledChanged();
    }
    if (entry.attachedConnection)
        disconnect(entry.attachedConnection);
    if (entry.item) {
        entry.item->setParentItem(nullptr);
        entry.item->setVisible(false);
        entry.item->deleteLater();
        entry.item = nullptr;
    }
    if (entry.context) {
        entry.context->deleteLater();
        entry.context = nullptr;
    }
}

void LazyListView::updateDelegateData(DelegateEntry& entry) {
    if (!m_model)
        return;

    const auto roleNames = m_model->roleNames();
    const auto index = m_model->index(entry.modelIndex, 0);
    bool hasModelData = false;

    for (auto it = roleNames.constBegin(); it != roleNames.constEnd(); ++it) {
        const auto name = QString::fromUtf8(it.value());
        const auto value = m_model->data(index, it.key());
        if (entry.context)
            entry.context->setContextProperty(name, value);
        if (entry.item)
            entry.item->setProperty(name.toUtf8().constData(), value);
        if (name == QStringLiteral("modelData"))
            hasModelData = true;
    }

    if (entry.context)
        entry.context->setContextProperty(QStringLiteral("index"), entry.modelIndex);
    if (entry.item)
        entry.item->setProperty("index", entry.modelIndex);

    if (!hasModelData) {
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        const auto value = m_model->data(index, role);
        if (entry.context)
            entry.context->setContextProperty(QStringLiteral("modelData"), value);
        if (entry.item)
            entry.item->setProperty("modelData", value);
    }
}

// --- Model Connection ---

void LazyListView::connectModel() {
    if (!m_model)
        return;

    m_modelConnections = {
        connect(m_model, &QAbstractItemModel::rowsInserted, this, &LazyListView::onRowsInserted),
        connect(m_model, &QAbstractItemModel::rowsAboutToBeRemoved, this, &LazyListView::onRowsAboutToBeRemoved),
        connect(m_model, &QAbstractItemModel::rowsRemoved, this, &LazyListView::onRowsRemoved),
        connect(m_model, &QAbstractItemModel::rowsMoved, this, &LazyListView::onRowsMoved),
        connect(m_model, &QAbstractItemModel::dataChanged, this, &LazyListView::onDataChanged),
        connect(m_model, &QAbstractItemModel::modelReset, this, &LazyListView::onModelReset),
        connect(m_model, &QAbstractItemModel::layoutChanged, this, [this] {
            for (auto& entry : m_delegates)
                updateDelegateData(entry);
            polish();
        }),
        connect(m_model, &QObject::destroyed, this,
            [this] {
                m_model = nullptr;
                resetContent();
                emit modelChanged();
            }),
    };
}

void LazyListView::disconnectModel() {
    for (auto& conn : m_modelConnections)
        disconnect(conn);
    m_modelConnections.clear();
}

void LazyListView::resetContent() {
    // Stop all animations and destroy all delegates
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    m_delegates.clear();

    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
    m_dyingDelegates.clear();

    if (m_activeAnimations != 0) {
        m_activeAnimations = 0;
        emit settledChanged();
    }

    // Reset pending state
    m_knownHeightSum = 0;
    m_knownHeightCount = 0;
    m_pendingAddAnimations.clear();

    // Rebuild layout from model
    m_layout.clear();
    if (m_model && m_componentComplete) {
        const int rows = m_model->rowCount();
        m_layout.resize(rows);
        for (int i = 0; i < rows; ++i) {
            m_layout[i].height = 0;
            m_layout[i].heightKnown = false;
        }
        emit countChanged();
    }

    polish();
}

void LazyListView::onRowsInserted(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int insertCount = last - first + 1;
    // Insert new layout records
    m_layout.insert(first, insertCount, ItemRecord{ 0, 0, false });

    // Shift existing delegate indices
    QHash<int, DelegateEntry> shifted;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        int newIdx = it.key() >= first ? it.key() + insertCount : it.key();
        auto entry = std::move(it.value());
        entry.modelIndex = newIdx;
        if (entry.context)
            entry.context->setContextProperty(QStringLiteral("index"), newIdx);
        shifted.insert(newIdx, std::move(entry));
    }
    m_delegates = std::move(shifted);

    // Queue add animations and mark displacement
    for (int i = first; i <= last; ++i)
        m_pendingAddAnimations.insert(i);

    emit countChanged();
    polish();
}

void LazyListView::onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    for (int i = first; i <= last; ++i) {
        if (!m_delegates.contains(i))
            continue;

        auto entry = m_delegates.take(i);
        entry.pendingRemoval = true;
        stopAnimation(entry);

        if (m_removeDuration > 0 && entry.item) {
            // Signal the delegate via attached property — QML handles the visual transition
            auto* attached = qobject_cast<LazyListViewAttached*>(
                qmlAttachedPropertiesObject<LazyListView>(entry.item, false));
            if (attached)
                attached->setRemoving(true);

            // Schedule destruction after the remove animation duration
            auto* item = entry.item;
            QTimer::singleShot(m_removeDuration, this, [this, item] {
                for (auto it = m_dyingDelegates.begin(); it != m_dyingDelegates.end(); ++it) {
                    if (it->item == item) {
                        destroyDelegate(*it);
                        m_dyingDelegates.erase(it);
                        return;
                    }
                }
            });
            m_dyingDelegates.append(std::move(entry));
        } else {
            destroyDelegate(entry);
        }
    }
}

void LazyListView::onRowsRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int removeCount = last - first + 1;

    // Untrack known heights being removed
    for (int i = first; i <= last; ++i) {
        if (m_layout[i].heightKnown)
            untrackHeight(m_layout[i].height);
    }

    // Remove layout records
    m_layout.remove(first, removeCount);

    // Shift remaining delegate indices down
    QHash<int, DelegateEntry> shifted;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        int newIdx = it.key() > last ? it.key() - removeCount : it.key();
        auto entry = std::move(it.value());
        entry.modelIndex = newIdx;
        if (entry.context)
            entry.context->setContextProperty(QStringLiteral("index"), newIdx);
        shifted.insert(newIdx, std::move(entry));
    }
    m_delegates = std::move(shifted);


    emit countChanged();
    polish();
}

void LazyListView::onRowsMoved(const QModelIndex& parent, int start, int end,
                               const QModelIndex& destination, int row) {
    if (parent.isValid() || destination.isValid())
        return;

    const int count = end - start + 1;
    const int dest = row > start ? row - count : row;

    // Reorder layout records
    QVector<ItemRecord> moved;
    moved.reserve(count);
    for (int i = start; i <= end; ++i)
        moved.append(m_layout[i]);
    m_layout.remove(start, count);
    for (int i = 0; i < count; ++i)
        m_layout.insert(dest + i, moved[i]);

    // Remap delegate indices to match new model order
    QHash<int, DelegateEntry> remapped;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        int oldIdx = it.key();
        int newIdx = oldIdx;

        if (oldIdx >= start && oldIdx <= end) {
            newIdx = dest + (oldIdx - start);
        } else {
            if (oldIdx > end)
                newIdx -= count;
            if (newIdx >= dest)
                newIdx += count;
        }

        auto entry = std::move(it.value());
        entry.modelIndex = newIdx;
        if (entry.context)
            entry.context->setContextProperty(QStringLiteral("index"), newIdx);
        remapped.insert(newIdx, std::move(entry));
    }
    m_delegates = std::move(remapped);

    polish();
}

void LazyListView::onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles) {
    Q_UNUSED(roles)

    if (topLeft.parent().isValid())
        return;

    for (int i = topLeft.row(); i <= bottomRight.row(); ++i) {
        if (m_delegates.contains(i))
            updateDelegateData(m_delegates[i]);
    }
}

void LazyListView::onModelReset() {
    if (!m_model) {
        resetContent();
        return;
    }

    const int newRows = m_model->rowCount();
    const int oldRows = static_cast<int>(m_layout.size());

    // Check if the model data actually changed
    if (newRows == oldRows) {
        const auto roleNames = m_model->roleNames();
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        bool changed = false;

        for (auto it = m_delegates.constBegin(); it != m_delegates.constEnd(); ++it) {
            if (!it->item || it.key() >= newRows) {
                changed = true;
                break;
            }
            const auto newData = m_model->data(m_model->index(it.key(), 0), role);
            const auto oldData = it->item->property("modelData");
            if (newData != oldData) {
                changed = true;
                break;
            }
        }

        if (!changed) {
            // Model content unchanged, just refresh delegate data
            for (auto& entry : m_delegates)
                updateDelegateData(entry);
            return;
        }
    }

    resetContent();
}

// --- Animation ---

void LazyListView::startAddAnimation(DelegateEntry& entry) {
    if (!entry.item || m_addDuration <= 0)
        return;

    stopAnimation(entry);

    auto* group = new QParallelAnimationGroup(this);

    if (!qFuzzyCompare(m_addFromOpacity, 1.0)) {
        auto* opacityAnim = new QPropertyAnimation(entry.item, "opacity");
        opacityAnim->setDuration(m_addDuration);
        opacityAnim->setEasingCurve(m_addCurve);
        opacityAnim->setStartValue(m_addFromOpacity);
        opacityAnim->setEndValue(1.0);
        group->addAnimation(opacityAnim);
        entry.item->setOpacity(m_addFromOpacity);
    }

    if (!qFuzzyCompare(m_addFromScale, 1.0)) {
        auto* scaleAnim = new QPropertyAnimation(entry.item, "scale");
        scaleAnim->setDuration(m_addDuration);
        scaleAnim->setEasingCurve(m_addCurve);
        scaleAnim->setStartValue(m_addFromScale);
        scaleAnim->setEndValue(1.0);
        group->addAnimation(scaleAnim);
        entry.item->setScale(m_addFromScale);
    }

    if (group->animationCount() == 0) {
        delete group;
        return;
    }

    entry.animation = group;
    ++m_activeAnimations;
    if (m_activeAnimations == 1)
        emit settledChanged();

    connect(group, &QAbstractAnimation::finished, this, &LazyListView::onAnimationFinished);
    group->start(QAbstractAnimation::DeleteWhenStopped);
}

void LazyListView::startRemoveAnimation(DelegateEntry& entry) {
    if (!entry.item || m_removeDuration <= 0)
        return;

    stopAnimation(entry);

    auto* group = new QParallelAnimationGroup(this);

    if (!qFuzzyCompare(m_removeToOpacity, 1.0)) {
        auto* opacityAnim = new QPropertyAnimation(entry.item, "opacity");
        opacityAnim->setDuration(m_removeDuration);
        opacityAnim->setEasingCurve(m_removeCurve);
        opacityAnim->setStartValue(entry.item->opacity());
        opacityAnim->setEndValue(m_removeToOpacity);
        group->addAnimation(opacityAnim);
    }

    if (!qFuzzyCompare(m_removeToScale, 1.0)) {
        auto* scaleAnim = new QPropertyAnimation(entry.item, "scale");
        scaleAnim->setDuration(m_removeDuration);
        scaleAnim->setEasingCurve(m_removeCurve);
        scaleAnim->setStartValue(entry.item->scale());
        scaleAnim->setEndValue(m_removeToScale);
        group->addAnimation(scaleAnim);
    }

    if (group->animationCount() == 0) {
        delete group;
        return;
    }

    entry.animation = group;
    ++m_activeAnimations;
    if (m_activeAnimations == 1)
        emit settledChanged();

    connect(group, &QAbstractAnimation::finished, this, &LazyListView::onAnimationFinished);
    group->start(QAbstractAnimation::DeleteWhenStopped);
}

void LazyListView::stopAnimation(DelegateEntry& entry) {
    if (!entry.animation)
        return;

    entry.animation->stop();
    entry.animation = nullptr;

    --m_activeAnimations;
    if (m_activeAnimations == 0)
        emit settledChanged();
}

void LazyListView::onAnimationFinished() {
    auto* group = qobject_cast<QParallelAnimationGroup*>(sender());

    // Clear animation pointer from live delegates
    for (auto& entry : m_delegates) {
        if (entry.animation == group)
            entry.animation = nullptr;
    }

    // Clean up dying delegates whose animation finished
    m_dyingDelegates.erase(std::remove_if(m_dyingDelegates.begin(), m_dyingDelegates.end(),
                               [this, group](DelegateEntry& entry) {
                                   if (entry.animation == group) {
                                       entry.animation = nullptr;
                                       destroyDelegate(entry);
                                       return true;
                                   }
                                   return false;
                               }),
        m_dyingDelegates.end());

    --m_activeAnimations;
    if (m_activeAnimations == 0)
        emit settledChanged();

    // Re-sync in case viewport changed during animation
    polish();
}

} // namespace caelestia::components
