# Kledingkast op Proxmox

Dit pakket installeert Kledingkast als een **unprivileged Debian LXC**, net als VoorraadThuis en BeatSync Studio. De app draait als systemd-service achter nginx; Docker is niet nodig. Standaard wordt DHCP gebruikt, met optioneel een vast IP. HTTPS wordt ingericht met een self-signed certificaat, zodat je de app op je telefoon kunt installeren.

## Installeren vanaf GitHub met één commando

Voer op de Proxmox-host als `root` uit:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Theberas04/kledingkast/main/deploy/proxmox/install.sh)
```

Alleen bestanden ophalen en controleren, zonder een container te maken:

```bash
FETCH_ONLY=1 bash <(curl -fsSL https://raw.githubusercontent.com/Theberas04/kledingkast/main/deploy/proxmox/install.sh)
```

Gebruik `bash <(curl ...)`, niet `curl ... | bash`. Het installatiescript haalt de bestanden van GitHub op, controleert ze en roept daarna de LXC-provisioning aan.

## Netwerk en instellingen

Standaard gebruikt de container `vmbr0`, DHCP, 512 MB RAM, 1 core en een disk van 6 GB (foto's nemen ruimte in). Pas instellingen aan met environmentvariabelen:

```bash
CTID=121 BRIDGE=vmbr0 ROOTFS_STORAGE=local-lvm \
  bash <(curl -fsSL https://raw.githubusercontent.com/Theberas04/kledingkast/main/deploy/proxmox/install.sh)
```

Voor een vast IP:

```bash
CTID=121 STATIC_IP=192.168.1.51/24 GATEWAY=192.168.1.1 \
  bash <(curl -fsSL https://raw.githubusercontent.com/Theberas04/kledingkast/main/deploy/proxmox/install.sh)
```

`TEMPLATE_STORAGE` staat standaard op `local`; gebruik `ROOTFS_STORAGE=local` als je Proxmox geen `local-lvm` heeft. Overige variabelen: `CT_HOSTNAME`, `DNS_SERVER`, `CORES`, `MEMORY`, `SWAP`, `DISK`, `DEBIAN_MAJOR` (standaard 12), `TARGET_DIR`, `BRANCH`.

## Toegang en HTTPS

Na installatie toont het script de URL: `https://<LXC-IP>/`. HTTPS gebruikt een self-signed certificaat, dus accepteer de browserwaarschuwing eenmalig. Dat is nodig om de app op je telefoon te installeren (PWA) en om foto's te maken via de camera. HTTP blijft ook beschikbaar op poort 80.

## Bijwerken

Haal de nieuwste appbestanden op en werk de bestaande container bij zonder de database en foto's te wissen:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Theberas04/kledingkast/main/deploy/proxmox/update-from-github.sh) 121
```

Vervang `121` door het CTID van je container. De updater downloadt en controleert alles eerst, zet het dan klaar in een tussenmap, wisselt pas als alles klopt en draait bij een fout automatisch de vorige versie terug.

## Beheer en back-up

```bash
pct exec 121 -- systemctl status kledingkast
pct exec 121 -- journalctl -u kledingkast -f
pct exec 121 -- systemctl restart kledingkast
pct exec 121 -- systemctl status nginx
```

Kleding, draaghistorie en wasbeurten staan in `/var/lib/kledingkast/kledingkast.db`; de foto's in `/var/lib/kledingkast/fotos`. Neem een Proxmox-containerback-up, of kopieer die twee paden apart. De app heeft geen login en is bedoeld voor het vertrouwde thuisnetwerk; stel hem niet rechtstreeks bloot aan internet.

## AI-tagging (optioneel)

Wil je dat Kledingkast zelf invult wat er op een foto staat, zet dan een OpenAI-compatibele dienst in de service-instellingen:

```bash
pct exec 121 -- systemctl edit kledingkast   # voeg toe:
#   [Service]
#   Environment=AI_BASE_URL=https://api.openai.com/v1
#   Environment=AI_API_KEY=...
#   Environment=AI_VISION_MODEL=gpt-4o
pct exec 121 -- systemctl restart kledingkast
```

Zonder deze instellingen blijft de knop **Foto lezen** verborgen en werkt alles met de hand. Zie ook `GET /api/config` voor de actieve stand.