ifeq ($(OS),Windows_NT)
RM = cmd /c del /f /q
else
RM = rm -f
endif

.PHONY: install
install:
ifeq ($(OS),Windows_NT)
	powershell -Command "Get-Item sass_embedded-*.zip | Expand-Archive -DestinationPath . -Force"
	powershell -Command "Get-Item protoc-*.zip | Expand-Archive -DestinationPath protoc -Force"
	./protoc/bin/protoc --ruby_out=. embedded_sass.proto
else
	tar -vxzf sass_embedded-*.tar.gz
	unzip -od protoc protoc-*.zip
	./protoc/bin/protoc --ruby_out=. embedded_sass.proto
endif

.PHONY: clean
clean:
ifeq ($(OS),Windows_NT)
	$(RM) /s sass_embedded protoc embedded_sass_pb.rb
else
	$(RM) -r sass_embedded protoc embedded_sass_pb.rb
endif

.PHONY: distclean
distclean: clean
	$(RM) embedded_sass.proto protoc-*.zip sass_embedded-*.tar.gz
