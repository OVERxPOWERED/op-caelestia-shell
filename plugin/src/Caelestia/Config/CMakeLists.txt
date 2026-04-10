qml_module(caelestia-config
    URI Caelestia.Config
    SOURCES
        config.hpp config.cpp
        configobject.hpp
        advancedconfig.hpp
        appearanceconfig.hpp
        backgroundconfig.hpp
        barconfig.hpp
        borderconfig.hpp
        controlcenterconfig.hpp
        dashboardconfig.hpp
        generalconfig.hpp
        launcherconfig.hpp
        lockconfig.hpp
        notifsconfig.hpp
        osdconfig.hpp
        serviceconfig.hpp
        sessionconfig.hpp
        sidebarconfig.hpp
        userpaths.hpp
        utilitiesconfig.hpp
        winfoconfig.hpp
        configobject.cpp
    LIBRARIES
        Qt::Quick
)
