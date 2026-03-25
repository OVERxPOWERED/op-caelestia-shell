#pragma once

#include "blobshape.hpp"

#include <qelapsedtimer.h>
#include <qqmlengine.h>

class BlobRect : public BlobShape {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(qreal stiffness READ stiffness WRITE setStiffness NOTIFY
            stiffnessChanged)
    Q_PROPERTY(
        qreal damping READ damping WRITE setDamping NOTIFY dampingChanged)
    Q_PROPERTY(qreal deformScale READ deformScale WRITE setDeformScale NOTIFY
            deformScaleChanged)

public:
    explicit BlobRect(QQuickItem* parent = nullptr);
    ~BlobRect() override;

    qreal stiffness() const { return m_stiffness; }

    void setStiffness(qreal s) {
        if (!qFuzzyCompare(m_stiffness, s)) {
            m_stiffness = s;
            emit stiffnessChanged();
        }
    }

    qreal damping() const { return m_damping; }

    void setDamping(qreal d) {
        if (!qFuzzyCompare(m_damping, d)) {
            m_damping = d;
            emit dampingChanged();
        }
    }

    qreal deformScale() const { return m_deformScale; }

    void setDeformScale(qreal s) {
        if (!qFuzzyCompare(m_deformScale, s)) {
            m_deformScale = s;
            emit deformScaleChanged();
        }
    }

signals:
    void stiffnessChanged();
    void dampingChanged();
    void deformScaleChanged();

protected:
    void updatePolish() override;
    void updatePhysics() override;

private:
    void checkAtRest(float speed);

    // Physics state
    QPointF m_prevScenePos;
    QElapsedTimer m_elapsed;
    bool m_physicsActive = false;
    bool m_hasPrevPos = false;

    // Symmetric 2x2 deformation matrix components (3 independent: m00, m01,
    // m11) Rest state is identity: m00=1, m01=0, m11=1
    float m_dm00 = 1.0f;
    float m_dm01 = 0.0f;
    float m_dm11 = 1.0f;

    // Spring velocities for each component
    float m_dmVel00 = 0.0f;
    float m_dmVel01 = 0.0f;
    float m_dmVel11 = 0.0f;

    qreal m_stiffness = 200.0;
    qreal m_damping = 16.0;
    qreal m_deformScale = 0.0005;
};
