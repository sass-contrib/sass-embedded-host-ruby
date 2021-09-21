ifeq ($(OS),Windows_NT)
RM = powershell -c "cmd.exe /c del /f /q /s"
else
RM = rm -fr
endif
EXTCONF = ruby -- extconf.rb --without-sass-embedded --without-sass-embedded-protocol --without-protoc

.PHONY: all
all: sass_embedded embedded_sass_pb.rb

.PHONY: install
install:

.PHONY: clean
clean:
	$(RM) embedded_sass_pb.rb protoc sass_embedded

.PHONY: distclean
distclean: clean
	$(RM) embedded_sass.proto protoc-*.zip sass_embedded-*.tar.gz

ifeq ($(OS),Windows_NT)
sass_embedded-*.zip:
else
sass_embedded-*.tar.gz:
endif
	$(EXTCONF) --with-sass-embedded

ifeq ($(OS),Windows_NT)
sass_embedded: sass_embedded-*.zip
	powershell -c "if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) { Get-Item $< | Expand-Archive -DestinationPath . -Force } else { cscript.exe unzip.vbs $< . }"
else
sass_embedded: sass_embedded-*.tar.gz
	tar -vxzf $<
endif

protoc-*.zip:
	$(EXTCONF) --with-protoc

protoc: protoc-*.zip
ifeq ($(OS),Windows_NT)
	powershell -c "if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) { Get-Item $< | Expand-Archive -DestinationPath $@ -Force } else { cscript.exe unzip.vbs $< $@ }"
else
	unzip -od $@ $<
endif

embedded_sass.proto:
	$(EXTCONF) --with-sass-embedded-protocol

%_pb.rb: %.proto protoc
	./protoc/bin/protoc --ruby_out=. $<
