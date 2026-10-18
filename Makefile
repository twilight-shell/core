PREFIX ?= /usr
QMLDIR ?= $(PREFIX)/lib/qt6/qml
DEST = $(DESTDIR)$(QMLDIR)/Twilight/Core

install:
	install -d $(DEST)
	cp -r Twilight/Core/. $(DEST)

uninstall:
	rm -rf $(DEST)

.PHONY: install uninstall
