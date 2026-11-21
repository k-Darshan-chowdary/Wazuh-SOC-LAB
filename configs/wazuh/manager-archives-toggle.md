# Temporary raw archive test (manager)

File: `/var/ossec/etc/ossec.conf`, inside `<global>`

| Setting | During proof | Normal |
|---|---|---|
| `<logall>` | no | **no** |
| `<logall_json>` | **yes** | **no** |

```bash
sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.phase4-backup
sudo grep -n "logall" /var/ossec/etc/ossec.conf
sudo systemctl restart wazuh-manager
sudo grep -iE 'calc.exe|CalculatorApp.exe' /var/ossec/logs/archives/archives.json | tail -n 5
# restore to "no", restart, confirm:
sudo systemctl is-active wazuh-manager
```

Leave archiving off after the proof, or every raw event consumes disk.
