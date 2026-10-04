# 🌐 Analyseur de Trames Ethernet en VHDL

> Circuit numérique en VHDL qui lit l'en-tête d'une trame Ethernet octet par octet, en extrait les adresses MAC source et destination et identifie le protocole transporté (IPv4, ARP, IPv6, VLAN) grâce au champ EtherType.

![VHDL](https://img.shields.io/badge/Langage-VHDL-5E3A8C)
![Xilinx ISE](https://img.shields.io/badge/Outil-Xilinx%20ISE%209-E0301E)
![Simulation](https://img.shields.io/badge/Simulation-ISim-blue)

🎥 **[Voir la vidéo de démonstration](https://drive.google.com/file/d/1I3r35Ilspj2tcSSo2P_F4zsZIEm72Y7a/view?usp=sharing)**

## 📌 Présentation

Les équipements réseau (commutateurs, routeurs, cartes réseau FPGA) analysent chaque trame Ethernet en matériel pour décider comment la traiter. Ce projet implémente cette première étape : l'**analyse de l'en-tête de 14 octets** d'une trame.

Le circuit reçoit les octets de la trame un par un, reconstitue les champs de l'en-tête et signale par des sorties dédiées le type de protocole détecté.

## 📦 Format de l'en-tête analysé

| Octets | Champ | Taille | Sortie du circuit |
|---|---|---|---|
| 0 à 5 | Adresse MAC destination | 6 octets | `mac_dst` |
| 6 à 11 | Adresse MAC source | 6 octets | `mac_src` |
| 12 à 13 | EtherType | 2 octets | `frame_type` |

### Protocoles reconnus

| EtherType | Protocole | Sortie activée |
|---|---|---|
| `0x0800` | IPv4 | `is_ipv4` |
| `0x0806` | ARP | `is_arp` |
| `0x86DD` | IPv6 | `is_ipv6` |
| `0x8100` | VLAN (802.1Q) | `is_vlan` |
| autre | Inconnu | `is_unknown` |

## 🔌 Interface du composant

| Signal | Sens | Largeur | Rôle |
|---|---|---|---|
| `clk` | entrée | 1 | Horloge |
| `rst` | entrée | 1 | Réinitialisation asynchrone (active à 1) |
| `data_in` | entrée | 8 | Octet courant de la trame |
| `data_valid` | entrée | 1 | Indique que `data_in` contient un octet valide |
| `frame_start` | entrée | 1 | Impulsion de début de trame |
| `mac_dst` | sortie | 48 | Adresse MAC destination |
| `mac_src` | sortie | 48 | Adresse MAC source |
| `frame_type` | sortie | 16 | Valeur du champ EtherType |
| `is_ipv4` / `is_arp` / `is_ipv6` / `is_vlan` / `is_unknown` | sortie | 1 chacune | Type de trame détecté |
| `frame_done` | sortie | 1 | Impulsion d'un cycle : l'en-tête est entièrement analysé |

## ⚙️ Fonctionnement

1. Une impulsion sur `frame_start` active l'analyse, remet le compteur d'octets à zéro et efface les indicateurs de type.
2. À chaque cycle où `data_valid = '1'`, l'octet présent sur `data_in` est rangé dans le registre correspondant à sa position (compteur `byte_count` de 0 à 13).
3. Au 14ᵉ octet, le circuit compare l'EtherType aux valeurs connues, active l'indicateur correspondant et émet une impulsion `frame_done`.
4. L'analyse s'arrête jusqu'à la prochaine impulsion `frame_start`.

Les octets sont pris en compte à partir du cycle qui suit `frame_start`.

## 📁 Contenu du dépôt

| Fichier | Rôle |
|---|---|
| `ethernet_parser.vhd` | Description du composant (architecture comportementale) |
| `tb_ethernet_parser.vhd` | Banc de test (testbench) pour la simulation |

## 🚀 Simulation

### Avec Xilinx ISE / ISim
1. Créer un projet ISE et ajouter `ethernet_parser.vhd` et `tb_ethernet_parser.vhd`.
2. Définir `tb_ethernet_parser` comme module de simulation.
3. Lancer *Simulate Behavioral Model* et observer les chronogrammes : `byte_count`, `mac_dst`, `mac_src`, `frame_type`, indicateurs `is_*` et `frame_done`.

### Avec GHDL (alternative libre)
```bash
ghdl -a --ieee=synopsys ethernet_parser.vhd tb_ethernet_parser.vhd
ghdl -e --ieee=synopsys tb_ethernet_parser
ghdl -r --ieee=synopsys tb_ethernet_parser --wave=ethernet.ghw
gtkwave ethernet.ghw
```

## 🔎 Périmètre et limites

- Le circuit analyse **uniquement l'en-tête de 14 octets** : le préambule, le contenu de la trame (payload) et le FCS ne sont pas traités.
- Le type VLAN (`0x8100`) est signalé, mais l'étiquette 802.1Q n'est pas décodée.

## 🔭 Améliorations possibles

- Décoder l'étiquette VLAN (priorité et identifiant)
- Traiter le payload et vérifier le FCS (CRC-32)
- Gérer les trames consécutives sans temps mort
- Synthétiser et tester le design sur une carte FPGA

## 🧠 Compétences mises en pratique

- Conception de circuits numériques en VHDL
- Machine séquentielle pilotée par compteur
- Connaissance du format des trames Ethernet
- Simulation et validation par testbench

## 👤 Auteure

**Safaa OUARD** — Étudiante ingénieure en Systèmes d'Information et de Communication, ENSA El Jadida
[GitHub](https://github.com/safaaOUARD)
