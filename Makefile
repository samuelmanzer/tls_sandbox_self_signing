# TLS generation sourced from this excellent guide:
# https://alexanderzeitler.com/articles/Fixing-Chrome-missing_subjectAltName-selfsigned-cert-openssl/

.PHONY: default run certs

default:
	@echo "Usage: (sudo) make [target"
	@echo "Targets:"
	@echo "\tcerts"
	@echo "\trun"

tls_dir := tls
ca_private_key = $(tls_dir)/private/rootCA.key
ca_cert = $(tls_dir)/certs/rootCA.pem
server_private_key = $(tls_dir)/private/ssl-cert-snakeoil.key
server_csr = $(tls_dir)/ssl-cert-snakeoil.csr
server_cert = $(tls_dir)/certs/ssl-cert-snakeoil.pem

$(tls_dir):
	mkdir $(tls_dir)
	mkdir $(tls_dir)/private
	mkdir $(tls_dir)/certs

$(ca_private_key): | $(tls_dir)
	openssl genrsa -out $(ca_private_key) 2048

$(ca_cert): $(ca_private_key) | $(tls_dir)
	openssl req -x509 \
		-new \
		-nodes \
		-key $(ca_private_key) \
	       	-sha256 \
		-days 1024 \
		-out $(ca_cert) \
		-config ca.cnf

$(server_csr): $(ca_cert)
	openssl req -new \
		-sha256 \
		-nodes \
		-newkey rsa:2048 \
		-keyout $(server_private_key)  \
		-out $(server_csr) \
		-config server.csr.cnf

$(server_cert): $(server_csr)
	openssl x509 -req \
		-in $(server_csr) \
		-CA $(ca_cert) \
		-CAkey $(ca_private_key) \
		-CAcreateserial \
		-out $(server_cert) \
		-days 365 \
		-sha256 \
		-extfile server.v3.ext

certs: $(server_cert)

run:
	docker run -d \
	--name ssl_sandbox_server \
	-v $(CURDIR)/$(tls_dir):/etc/ssl \
	-p 80:80 -p 443:443 \
	eboraas/apache
