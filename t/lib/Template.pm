unit module Template;

sub docker-makefile(%project) returns Str is export {
    qq{
.PHONY: test build detach

ROOT_DIR:=\$(shell dirname \$(realpath \$(lastword \$(MAKEFILE_LIST))))

title:
	@echo "%project<title> "

test: title
	@echo "├─ Phase: Test"

build: test
	@echo "├─ Phase: Build"
	docker build -t %project<name> .

detach: build
	@echo "└─ Phase: Run"
	docker run \\
		--name %project<name> \\
		--hostname %project<name>.local \\
		--detach \\
		--interactive=true \\
		--tty=true \\
		--rm \\
		--volume \$(shell dirname \$(ROOT_DIR))/html:/usr/share/nginx/html:ro \\
		%project<name> nginx -g 'daemon off;'
    }.trim;
}

sub docker-dockerfile(%project) returns Str is export {
	q{
FROM nginx:alpine
	}.trim;
}

sub html-welcome(%project) returns Str is export {
	qq{
<!DOCTYPE html>
<html>
<head><title>%project<title>\</title></head>
<body>
<h2>Welcome to %project<title>\</h2>
<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc in libero dui. Curabitur eget iaculis ex. Nam pellentesque euismod augue, quis porttitor massa facilisis sit amet. Nulla a diam tempus augue pharetra congue.</p>
</body>
</html>
	}.trim;
}

# vim:noexpandtab
