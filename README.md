# QUBIP Fedora Reference Container Image

This container image provides a reference environment based on Fedora
with the correct configuration changes to enable post-quantum cryptography.

## Building the container

To build the container on your local system, you can use `podman build`. Make
sure that your current working directory contains the `Containerfile` when
running this.

```sh
podman build -t pq-httpd-container .
```

To run the container, use

```sh
podman run \
	--rm \
	-it \
	pq-httpd-container

```

## Things to test in the container

The following is a list of items to test inside the container to show that it
has been configured for post-quantum cryptography.

### Listing the enabled OpenSSL Providers

```sh
openssl list -providers
```

will list the OpenSSL OQS Provider, which uses liboqs to offer post-quantum
cryptography for OpenSSL.

### Showing the active system-wide cryptographic policy

Fedora provides a global configuration mechanism for all its cryptographic
libraries called `crypto-policies`. The `crypto-policies` package in Fedora has
a policy module that enables post-quantum cryptography called `TEST-PQ`.

It is already enabled in the container. You can verify this by running

```sh
update-crypto-policies --show
```

which will return `DEFAULT:TEST-PQ`. If the `TEST-PQ` policy module is not
enabled, it can be by running

```sh
update-crypto-policies --set DEFAULT:TEST-PQ
```

### Connecting using ML-KEM key exchange to openquantumsafe.org

To connect to openquantumsafe.org's test server using post-quantum cryptography
for the key exchange, use the `s_client` OpenSSL command:

```sh
openssl s_client \
	-connect test.openquantumsafe.org:6041 \
	-trace
```

### Connecting to PQC-enabled apache webserver running in the container

An instance of the apache webserver is configured to use post-quantum
cryptography key exchange in the container and will listen on port 443.

First, you need to start it by running

```sh
httpd
```

Next, you can use OpenSSL's `s_client` to connect to it:

```sh
openssl s_client \
	-CAfile root.crt \
	-tls1_3 \
	-trace \
	-connect localhost:443
```

To test OpenSSL with `curl`, use the following command:

```sh
curl \
	--cacert root.crt \
	https://localhost/
```



# Replicating the container's setup on Fedora rawhide

The setup inside of the container can also be replicated manually on any Fedora
rawhide installation by following the steps below:

1. Install the required packages:  
   ```sh
   sudo dnf install openssl curl oqsprovider crytpo-policies-scripts sed
   ```
2. Switch the system-wide cryptographic policy to include the `TEST-PQ` policy
   module, which enables post-quantum algorithms:  
   ```sh
   sudo update-crypto-policies --set DEFAULT:TEST-PQ
   ```
3. Enable the OpenSSL OQS Provider:  
   ```sh
	sudo sed -i '/default = default_sect/a oqsprovider = oqs_sect' /etc/pki/tls/openssl.cnf

	sudo sed -i '/activate = 1/ {
	a [oqs_sect]
	a activate = 1
	}' /etc/pki/tls/openssl.cnf
   ```

This enables key exchange with post-quantum cryptography in TLS in both clients
and servers that use OpenSSL.
