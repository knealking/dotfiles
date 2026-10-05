# Extras

## Linux Cac

```bash
mkdir -p $HOME/.pki/nssdb
certutil -N -d sql:$HOME/.pki/nssdb --empty-password
curl -fsSL https://raw.githubusercontent.com/jdjaxon/linux_cac/main/cac_setup.sh | sudo bash
modutil -dbdir sql:$HOME/.pki/nssdb/ \
    -add "CAC Module" \
    -libfile /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so
```

## pwndbg

```bash
uv tool install git+https://github.com/pwndbg/pwndbg
echo "source $(uv tool dir)/pwndbg/share/pwndbg/gdbinit.py" >> ~/.gdbinit
```
