.PHONY: install
install:
ifeq ($(OS),Windows_NT)
	powershell -command "Get-Item sass_embedded-*.zip | Expand-Archive -DestinationPath (Get-Location) -Force"
	powershell -command "Get-Item protoc-*.zip | Expand-Archive -DestinationPath protoc -Force"
	./protoc/bin/protoc --ruby_out=. embedded_sass.proto
else
	tar -vxzf sass_embedded-*.tar.gz
	unzip -od protoc protoc-*.zip
	./protoc/bin/protoc --ruby_out=. embedded_sass.proto
endif

.PHONY: clean
clean:
ifeq ($(OS),Windows_NT)
	powershell -command "Remove-Item sass_embedded -Recurse -Force -ErrorAction Ignore"
	powershell -command "Remove-Item protoc -Recurse -Force -ErrorAction Ignore"
	powershell -command "Remove-Item embedded_sass_pb.rb -Recurse -Force -ErrorAction Ignore"
else
	rm -rf sass_embedded
	rm -rf protoc
	rm -rf embedded_sass_pb.rb
endif

.PHONY: distclean
distclean: clean
ifeq ($(OS),Windows_NT)
	powershell -command "Remove-Item sass_embedded-*.zip -Force -ErrorAction Ignore"
	powershell -command "Remove-Item protoc-*.zip -Force -ErrorAction Ignore"
	powershell -command "Remove-Item embedded_sass.proto -Force -ErrorAction Ignore"
else
	rm -rf sass_embedded-*.tar.gz
	rm -rf protoc-*.zip
	rm -rf embedded_sass.proto
endif
