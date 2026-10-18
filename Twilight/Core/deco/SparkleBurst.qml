import QtQuick
import QtQuick.Particles
import ".."

// Magic sparks: call burst(x, y, count) to throw stars out of a point.
// The system only runs while sparks are alive: a running ParticleSystem
// ticks every frame even when empty, which kept whole windows redrawing.
ParticleSystem {
    id: system

    running: false

    function burst(x, y, count) {
        running = true;
        emitter.burst(count, x, y);
        settle.restart();
    }

    Timer {
        id: settle

        interval: emitter.lifeSpan + emitter.lifeSpanVariation + 100
        onTriggered: system.running = false
    }

    ItemParticle {
        system: system
        fade: true

        delegate: StyledText {
            outlined: true
            text: ["✦", "✧", "★", "⋆"][Math.floor(Math.random() * 4)]
            color: [Theme.star, Theme.primary, Theme.text, Theme.accent][Math.floor(Math.random() * 4)]
            font.pixelSize: 9 + Math.random() * 14
        }
    }

    Emitter {
        id: emitter

        system: system
        enabled: false
        lifeSpan: 900
        lifeSpanVariation: 300

        velocity: AngleDirection {
            angleVariation: 360
            magnitude: 240
            magnitudeVariation: 140
        }

        acceleration: PointDirection {
            y: 320
        }
    }
}
