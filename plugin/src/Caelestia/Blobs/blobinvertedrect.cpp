#include "blobinvertedrect.hpp"
#include "blobgroup.hpp"

BlobInvertedRect::BlobInvertedRect(QQuickItem* parent)
    : BlobShape(parent) {}

BlobInvertedRect::~BlobInvertedRect() {
    if (m_group)
        m_group->clearInvertedRect(this);
}

void BlobInvertedRect::setBorderLeft(qreal v) {
    if (qFuzzyCompare(m_borderLeft, v))
        return;
    m_borderLeft = v;
    emit borderLeftChanged();
    if (m_group)
        m_group->markDirty();
}

void BlobInvertedRect::setBorderRight(qreal v) {
    if (qFuzzyCompare(m_borderRight, v))
        return;
    m_borderRight = v;
    emit borderRightChanged();
    if (m_group)
        m_group->markDirty();
}

void BlobInvertedRect::setBorderTop(qreal v) {
    if (qFuzzyCompare(m_borderTop, v))
        return;
    m_borderTop = v;
    emit borderTopChanged();
    if (m_group)
        m_group->markDirty();
}

void BlobInvertedRect::setBorderBottom(qreal v) {
    if (qFuzzyCompare(m_borderBottom, v))
        return;
    m_borderBottom = v;
    emit borderBottomChanged();
    if (m_group)
        m_group->markDirty();
}

void BlobInvertedRect::registerWithGroup() {
    if (m_group)
        m_group->setInvertedRect(this);
}

void BlobInvertedRect::unregisterFromGroup() {
    if (m_group)
        m_group->clearInvertedRect(this);
}
