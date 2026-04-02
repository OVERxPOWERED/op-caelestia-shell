#pragma once

#include <qabstractitemmodel.h>
#include <qeasingcurve.h>
#include <qhash.h>
#include <qobject.h>
#include <qparallelanimationgroup.h>
#include <qqmlcomponent.h>
#include <qqmlcontext.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qrect.h>
#include <qvector.h>

namespace caelestia::components {

class LazyListViewAttached : public QObject {
    Q_OBJECT

    Q_PROPERTY(qreal preferredHeight READ preferredHeight WRITE setPreferredHeight NOTIFY preferredHeightChanged)

public:
    explicit LazyListViewAttached(QObject* parent = nullptr);

    [[nodiscard]] qreal preferredHeight() const;
    void setPreferredHeight(qreal height);

signals:
    void preferredHeightChanged();

private:
    qreal m_preferredHeight = -1;
};

class LazyListView : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(LazyListViewAttached)

    // Model & Delegate
    Q_PROPERTY(QAbstractItemModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QQmlComponent* delegate READ delegate WRITE setDelegate NOTIFY delegateChanged)

    // Layout
    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    Q_PROPERTY(qreal contentHeight READ contentHeight NOTIFY contentHeightChanged)
    Q_PROPERTY(qreal contentY READ contentY WRITE setContentY NOTIFY contentYChanged)

    // Viewport & Lazy Loading
    Q_PROPERTY(QRectF viewport READ viewport WRITE setViewport NOTIFY viewportChanged)
    Q_PROPERTY(bool useCustomViewport READ useCustomViewport WRITE setUseCustomViewport NOTIFY useCustomViewportChanged)
    Q_PROPERTY(qreal cacheBuffer READ cacheBuffer WRITE setCacheBuffer NOTIFY cacheBufferChanged)

    // Sizing
    Q_PROPERTY(qreal estimatedHeight READ estimatedHeight WRITE setEstimatedHeight NOTIFY estimatedHeightChanged)

    // Add Animation
    Q_PROPERTY(int addDuration READ addDuration WRITE setAddDuration NOTIFY addDurationChanged)
    Q_PROPERTY(QEasingCurve addCurve READ addCurve WRITE setAddCurve NOTIFY addCurveChanged)
    Q_PROPERTY(qreal addFromOpacity READ addFromOpacity WRITE setAddFromOpacity NOTIFY addFromOpacityChanged)
    Q_PROPERTY(qreal addFromScale READ addFromScale WRITE setAddFromScale NOTIFY addFromScaleChanged)

    // Remove Animation
    Q_PROPERTY(int removeDuration READ removeDuration WRITE setRemoveDuration NOTIFY removeDurationChanged)
    Q_PROPERTY(QEasingCurve removeCurve READ removeCurve WRITE setRemoveCurve NOTIFY removeCurveChanged)
    Q_PROPERTY(qreal removeToOpacity READ removeToOpacity WRITE setRemoveToOpacity NOTIFY removeToOpacityChanged)
    Q_PROPERTY(qreal removeToScale READ removeToScale WRITE setRemoveToScale NOTIFY removeToScaleChanged)

    // Move/Displaced Animation
    Q_PROPERTY(int moveDuration READ moveDuration WRITE setMoveDuration NOTIFY moveDurationChanged)
    Q_PROPERTY(QEasingCurve moveCurve READ moveCurve WRITE setMoveCurve NOTIFY moveCurveChanged)

    // State
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool settled READ settled NOTIFY settledChanged)

public:
    explicit LazyListView(QQuickItem* parent = nullptr);
    ~LazyListView() override;

    static LazyListViewAttached* qmlAttachedProperties(QObject* object);

    // Model & Delegate
    [[nodiscard]] QAbstractItemModel* model() const;
    void setModel(QAbstractItemModel* model);

    [[nodiscard]] QQmlComponent* delegate() const;
    void setDelegate(QQmlComponent* delegate);

    // Layout
    [[nodiscard]] qreal spacing() const;
    void setSpacing(qreal spacing);

    [[nodiscard]] qreal contentHeight() const;

    [[nodiscard]] qreal contentY() const;
    void setContentY(qreal contentY);

    // Viewport
    [[nodiscard]] QRectF viewport() const;
    void setViewport(const QRectF& viewport);

    [[nodiscard]] bool useCustomViewport() const;
    void setUseCustomViewport(bool use);

    [[nodiscard]] qreal cacheBuffer() const;
    void setCacheBuffer(qreal buffer);

    // Sizing
    [[nodiscard]] qreal estimatedHeight() const;
    void setEstimatedHeight(qreal height);

    // Add Animation
    [[nodiscard]] int addDuration() const;
    void setAddDuration(int duration);

    [[nodiscard]] QEasingCurve addCurve() const;
    void setAddCurve(const QEasingCurve& curve);

    [[nodiscard]] qreal addFromOpacity() const;
    void setAddFromOpacity(qreal opacity);

    [[nodiscard]] qreal addFromScale() const;
    void setAddFromScale(qreal scale);

    // Remove Animation
    [[nodiscard]] int removeDuration() const;
    void setRemoveDuration(int duration);

    [[nodiscard]] QEasingCurve removeCurve() const;
    void setRemoveCurve(const QEasingCurve& curve);

    [[nodiscard]] qreal removeToOpacity() const;
    void setRemoveToOpacity(qreal opacity);

    [[nodiscard]] qreal removeToScale() const;
    void setRemoveToScale(qreal scale);

    // Move Animation
    [[nodiscard]] int moveDuration() const;
    void setMoveDuration(int duration);

    [[nodiscard]] QEasingCurve moveCurve() const;
    void setMoveCurve(const QEasingCurve& curve);

    // State
    [[nodiscard]] int count() const;
    [[nodiscard]] bool settled() const;

signals:
    void modelChanged();
    void delegateChanged();
    void spacingChanged();
    void contentHeightChanged();
    void contentYChanged();
    void viewportChanged();
    void useCustomViewportChanged();
    void cacheBufferChanged();
    void estimatedHeightChanged();
    void addDurationChanged();
    void addCurveChanged();
    void addFromOpacityChanged();
    void addFromScaleChanged();
    void removeDurationChanged();
    void removeCurveChanged();
    void removeToOpacityChanged();
    void removeToScaleChanged();
    void moveDurationChanged();
    void moveCurveChanged();
    void countChanged();
    void settledChanged();

protected:
    void componentComplete() override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void updatePolish() override;

private:
    struct ItemRecord {
        qreal targetY = 0;
        qreal height = 0;
        bool heightKnown = false;
    };

    struct DelegateEntry {
        int modelIndex = -1;
        QQuickItem* item = nullptr;
        QQmlContext* context = nullptr;
        bool pendingRemoval = false;
        QParallelAnimationGroup* animation = nullptr;
        QMetaObject::Connection attachedConnection;
    };

    // Layout
    void relayout();
    [[nodiscard]] std::pair<int, int> computeVisibleRange() const;
    [[nodiscard]] QRectF effectiveViewport() const;
    [[nodiscard]] qreal effectiveEstimatedHeight() const;
    [[nodiscard]] static qreal delegateHeight(QQuickItem* item);
    void trackHeight(qreal height);
    void untrackHeight(qreal height);

    // Delegate lifecycle
    void syncDelegates();
    DelegateEntry createDelegate(int modelIndex);
    void destroyDelegate(DelegateEntry& entry);
    void updateDelegateData(DelegateEntry& entry);

    // Model connection
    void connectModel();
    void disconnectModel();
    void resetContent();
    void onRowsInserted(const QModelIndex& parent, int first, int last);
    void onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last);
    void onRowsRemoved(const QModelIndex& parent, int first, int last);
    void onRowsMoved(const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row);
    void onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles);
    void onModelReset();

    // Animation
    void startAddAnimation(DelegateEntry& entry);
    void startRemoveAnimation(DelegateEntry& entry);
    void startMoveAnimation(DelegateEntry& entry, qreal fromY);
    void stopAnimation(DelegateEntry& entry);
    void onAnimationFinished();

    // Members
    QAbstractItemModel* m_model = nullptr;
    QQmlComponent* m_delegate = nullptr;

    qreal m_spacing = 0;
    qreal m_contentHeight = 0;
    qreal m_contentY = 0;

    QRectF m_viewport;
    bool m_useCustomViewport = false;
    qreal m_cacheBuffer = 0;

    qreal m_estimatedHeight = -1;
    qreal m_knownHeightSum = 0;
    int m_knownHeightCount = 0;

    int m_addDuration = 300;
    QEasingCurve m_addCurve;
    qreal m_addFromOpacity = 0;
    qreal m_addFromScale = 1;

    int m_removeDuration = 300;
    QEasingCurve m_removeCurve;
    qreal m_removeToOpacity = 0;
    qreal m_removeToScale = 1;

    int m_moveDuration = 300;
    QEasingCurve m_moveCurve;

    QVector<ItemRecord> m_layout;
    QHash<int, DelegateEntry> m_delegates;
    QVector<DelegateEntry> m_dyingDelegates;
    QVector<DelegateEntry> m_delegatePool;

    int m_activeAnimations = 0;
    bool m_componentComplete = false;
    bool m_animateDisplacement = false;
    QSet<int> m_pendingAddAnimations;

    QList<QMetaObject::Connection> m_modelConnections;
};

} // namespace caelestia::components
