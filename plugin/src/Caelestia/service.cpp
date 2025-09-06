#include "service.hpp"

#include <QDebug>
#include <QObject>

namespace caelestia {

Service::Service(QObject* parent)
    : QObject(parent)
    , m_refCount(0) {}

int Service::refCount() const {
    return m_refCount;
}

void Service::ref() {
    if (m_refCount == 0) {
        start();
    }

    m_refCount++;
    emit refCountChanged();
}

void Service::unref() {
    if (m_refCount == 0) {
        qWarning() << "ServiceRef::unref: attempted to unref service with no active refs";
        return;
    }

    m_refCount--;
    emit refCountChanged();

    if (m_refCount == 0) {
        stop();
    }
}

} // namespace caelestia
