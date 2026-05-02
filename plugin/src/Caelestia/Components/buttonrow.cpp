#include "buttonrow.hpp"

namespace caelestia::components {

ButtonRow::ButtonRow(QQuickItem* parent)
    : QQuickItem(parent)
    , m_dirty(false)
    , m_spacing(0.0) {
    setFlag(QQuickItem::ItemHasContents, true);
    QObject::connect(this, &ButtonRow::widthChanged, this, &ButtonRow::invalidate);
}

qreal ButtonRow::spacing() const {
    return m_spacing;
}

void ButtonRow::setSpacing(qreal spacing) {
    if (qFuzzyCompare(m_spacing + 1.0, spacing + 1.0))
        return;

    m_spacing = spacing;
    emit spacingChanged();

    invalidate();
}

void ButtonRow::itemChange(QQuickItem::ItemChange change, const QQuickItem::ItemChangeData& data) {
    if (change == QQuickItem::ItemChildAddedChange) {
        auto* const child = data.item;
        QObject::connect(child, &QQuickItem::implicitWidthChanged, this, &ButtonRow::invalidate);
        QObject::connect(child, &QQuickItem::implicitHeightChanged, this, &ButtonRow::invalidate);
        QObject::connect(child, &QQuickItem::visibleChanged, this, &ButtonRow::invalidate);

        const auto* childMeta = child->metaObject();
        const auto morphSignalIdx = childMeta->indexOfSignal("shapeMorphExpansionChanged()");
        if (morphSignalIdx != -1)
            QObject::connect(child, childMeta->method(morphSignalIdx), this,
                metaObject()->method(metaObject()->indexOfSlot("invalidate()")));

        invalidate();
    } else if (change == QQuickItem::ItemChildRemovedChange) {
        QObject::disconnect(data.item, nullptr, this, nullptr);
        invalidate();
    }

    QQuickItem::itemChange(change, data);
}

void ButtonRow::updatePolish() {
    if (m_dirty) {
        relayout();
        m_dirty = false;
    }
}

void ButtonRow::invalidate() {
    m_dirty = true;
    polish();
}

void ButtonRow::relayout() {
    const auto children = childItems();
    const auto nChildren = children.size();
    const auto totalSpacing = static_cast<qreal>(nChildren - 1) * m_spacing;

    qreal reservedWidth = 0;
    int fillWidthCount = 0;
    qreal maxHeight = 0;
    for (auto* const child : children) {
        if (!child->isVisible())
            continue;

        maxHeight = qMax(maxHeight, child->implicitHeight());

        const auto prop = child->property("fillWidth");
        if (!prop.isValid())
            continue;

        if (prop.toBool())
            fillWidthCount++;
        else
            reservedWidth += child->implicitWidth();
    }

    if (fillWidthCount == 0)
        fillWidthCount = 1; // Avoid divide by 0

    qreal accX = 0;
    const auto widthPerItem = (width() - totalSpacing - reservedWidth) / static_cast<qreal>(fillWidthCount);
    for (int i = 0; i < nChildren; ++i) {
        auto* const child = children[i];
        if (!child->isVisible())
            continue;

        auto prevExtraWidth = i > 0 ? getMorphExpansion(children[i - 1]) : 0.0;
        auto nextExtraWidth = i < nChildren - 1 ? getMorphExpansion(children[i + 1]) : 0.0;

        // Items at edges push by full amount, items in middle push by half
        if (i > 1)
            prevExtraWidth /= 2;
        if (i < nChildren - 2)
            nextExtraWidth /= 2;

        const auto childWidth = child->property("fillWidth").toBool() ? widthPerItem : child->implicitWidth();

        child->setWidth(childWidth + getMorphExpansion(child, childWidth) - prevExtraWidth - nextExtraWidth);
        child->setHeight(maxHeight);

        child->setX(accX);
        child->setY(0);
        accX += child->width() + m_spacing;
    }

    setImplicitWidth(reservedWidth + totalSpacing);
    setImplicitHeight(maxHeight);
}

qreal ButtonRow::getMorphExpansion(const QQuickItem* item) {
    return getMorphExpansion(item, item->implicitWidth());
}

qreal ButtonRow::getMorphExpansion(const QQuickItem* item, qreal width) {
    const auto prop = item->property("shapeMorphExpansion");
    return width * (prop.isValid() ? prop.toReal() - 1 : 0.0);
}

} // namespace caelestia::components
