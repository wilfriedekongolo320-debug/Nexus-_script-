#!/usr/bin/env bash

# ==============================================================================
# CONFIGURATION ET VARIABLES CONSERVÉES
# ==============================================================================
MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || echo "N/A")
readonly SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Nexus-_script-/main"
VERSION_FILE="/etc/version"

# ==============================================================================
# PALETTE COLORIMÉTRIQUE NEON CYBERPUNK (ANSI 256 / TRUE COLOR)
# ==============================================================================
NC='\033[0m'               # Reset
C_BOLD='\033[1m'
C_CYAN='\033[38;5;45m'      # Cyan brillant
C_BLUE='\033[38;5;201m'   # Bleu électrique
C_GREEN='\033[38;5;46m'     # Vert néon
C_GOLD='\033[38;5;220m'      # Jaune or
C_RED='\033[38;5;196m'       # Rouge néon
C_BLUE='\033[38;5;39m'      # Bleu électrique
C_GRAY='\033[38;5;242m'      # Gris sombre
C_WHITE='\033[38;5;255m'     # Blanc pur

# ==============================================================================
# FONCTIONS UTILES & CALCUL DES BARS CPU/RAM
# ==============================================================================
draw_cyber_bar() {
    local val=${1:-0}
    local filled=$(( val / 10 ))
    local empty=$(( 10 - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="▒"; done
    echo "$bar"
}

version_greater() {
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ] && [ "$1" != "$2" ]
}

# Metrics système
domain=$(cat /etc/xray/domain 2>/dev/null || cat /etc/domain 2>/dev/null || echo "N/A")
uptime="$(uptime -p 2>/dev/null | sed 's/up //' | cut -d " " -f 1-6)"
IPV4=$(curl -s -4 --max-time 3 ifconfig.co || echo "$MYIP")
IPV6=$(curl -s -6 --max-time 3 ifconfig.co || echo "")

INSTALLED_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0")
LATEST_VERSION=$(curl -sS --max-time 3 "$SERVER_HOST/version" 2>/dev/null || echo "$INSTALLED_VERSION")
UPDATE_AVAILABLE=0

CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
RAM_USAGE=$(free 2>/dev/null | awk '/Mem:/ {print int($3/$2 * 100)}')

CPU_BAR=$(draw_cyber_bar ${CPU_USAGE:-0})
RAM_BAR=$(draw_cyber_bar ${RAM_USAGE:-0})

# Mettre à jour si nécessaire
if version_greater "$LATEST_VERSION" "$INSTALLED_VERSION"; then
    UPDATE_AVAILABLE=1
    wget -q -O /usr/local/sbin/update "$SERVER_HOST/menu/update.sh" && chmod +x /usr/local/sbin/update
fi

# Détection de l'OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS="$NAME"
    VER="$VERSION_ID"
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

# Vérification des services en cours
nginx=$(systemctl is-active nginx 2>/dev/null)
[[ $nginx == "active" ]] && status_nginx="${C_GREEN}⚡ RUN${NC}" || status_nginx="${C_RED}✖ OFF${NC}"

xray=$(systemctl is-active xray 2>/dev/null)
[[ $xray == "active" ]] && status_xray="${C_GREEN}⚡ RUN${NC}" || status_xray="${C_RED}✖ OFF${NC}"

ssh_ws=$(systemctl is-active ws-stunnel 2>/dev/null)
[[ $ssh_ws == "active" ]] && status_ws="${C_GREEN}⚡ RUN${NC}" || status_ws="${C_RED}✖ OFF${NC}"

clear

# ==============================================================================
# 1. BANNIÈRE ASCII CENTRÉE
# ==============================================================================
read -r -d '' BANNER << 'EOF'
████████╗██╗  ██╗███████╗    ███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝
   ██║   ███████║█████╗      ███████╗
   ██║   ██╔══██║██╔══╝      ╚════██║
   ██║   ██║  ██║███████╗    ███████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚══════╝
EOF

TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
echo -e "${C_GOLD}${C_BOLD}"
while IFS= read -r line; do
    LINE_LEN=${#line}
    PADDING=$(( (TERM_WIDTH - LINE_LEN) / 2 ))
    if [ $PADDING -gt 0 ]; then
        printf "%*s%s\n" "$PADDING" "" "$line"
    else
        echo "$line"
    fi
done <<< "$BANNER"
echo -e "${NC}"

# ==============================================================================
# 2. MATRICE INFOS SYSTÈME ET SERVICES
# ==============================================================================
echo -e "${C_MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${C_MAGENTA}║${NC} ${C_BOLD}${C_CYAN}🇨🇲THE_S🔥TUNNEL PRO - SYSTEM ${NC}                ${C_MAGENTA}║${NC}"
echo -e "${C_MAGENTA}╠══════════════════════════════════════════════════════════╣${NC}"
printf "${C_MAGENTA}║${NC}  ${C_WHITE}OS${NC}     : %-18s  ${C_WHITE}UPTIME${NC} : %-16s ${C_MAGENTA}║${NC}\n" "$OS $VER" "${uptime:-N/A}"
printf "${C_MAGENTA}║${NC}  ${C_WHITE}CPU${NC}    : [${C_CYAN}%s${NC}] %-3d%%    ${C_WHITE}RAM${NC}    : [${C_CYAN}%s${NC}] %-3d%%    ${C_MAGENTA}║${NC}\n" "$CPU_BAR" "${CPU_USAGE:-0}" "$RAM_BAR" "${RAM_USAGE:-0}"
printf "${C_MAGENTA}║${NC}  ${C_WHITE}IPv4${NC}   : %-18s  ${C_WHITE}DOMAIN${NC} : %-16s ${C_MAGENTA}║${NC}\n" "${IPV4:-N/A}" "${domain:-N/A}"
if [ -n "$IPV6" ]; then
printf "${C_MAGENTA}║${NC}  ${C_WHITE}IPv6${NC}   : %-47s ${C_MAGENTA}║${NC}\n" "$IPV6"
fi
echo -e "${C_MAGENTA}╠══════════════════════════════════════════════════════════╣${NC}"
printf "${C_MAGENTA}║${NC}   NGINX : [%b]     XRAY : [%b]     WS : [%b]   ${C_MAGENTA}║${NC}\n" "$status_nginx" "$status_xray" "$status_ws"
echo -e "${C_MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# 3. PANNEAUX DE COMMANDES & SERVICES
# ==============================================================================
echo -e "${C_CYAN}►► MENU CORE ──────────────────────────────────────────────────${NC}"
echo -e "   ${C_MAGENTA}[01]${NC} • SSH/WS MENU             ${C_MAGENTA}[04]${NC} • TROJAN MENU"
echo -e "   ${C_MAGENTA}[02]${NC} • VMESS MENU              ${C_MAGENTA}[05]${NC} • SOCKS MENU"
echo -e "   ${C_MAGENTA}[03]${NC} • VLESS MENU              ${C_MAGENTA}[06]${NC} • ZIVPN MENU"
echo ""

echo -e "${C_CYAN}►► TOOLS & SYSTEM ─────────────────────────────────────────────${NC}"
echo -e "   ${C_BLUE}[07]${NC} • DNS PANEL               ${C_BLUE}[11]${NC} • NETGUARD PANEL"
echo -e "   ${C_BLUE}[08]${NC} • DOMAIN PANEL            ${C_BLUE}[12]${NC} • VPN PORT INFO"
echo -e "   ${C_BLUE}[09]${NC} • IPV6 PANEL              ${C_BLUE}[13]${NC} • CLEAN VPS LOGS"
echo -e "   ${C_BLUE}[10]${NC} • VPS STATUS              ${C_BLUE}[14]${NC} • TELEGRAM BOT PANEL"
echo -e "   ${C_RED}[15]${NC} • UNINSTALL NEXUS         ${C_BLUE}[16]${NC} • FAST DNS MENU"
echo -e "   ${C_GRAY}[00] • EXIT SESSION${NC}            ${C_RED}[88]${NC} • REBOOT VPS"
echo ""

echo -e "${C_CYAN}►► WEB CONTROL ────────────────────────────────────────────────${NC}"
echo -e "   ${C_GOLD}[18]${NC} • NEXUS TUNNEL WEB"
echo ""

if [ "$UPDATE_AVAILABLE" -eq 1 ]; then
    echo -e "${C_RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C_RED}║${NC} ${C_BOLD}[99] • UPDATE SCRIPT AVAILABLE (v$LATEST_VERSION)${NC}"
    echo -e "${C_RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
fi

# ==============================================================================
# 4. FOOTER & CONTACT INFO
# ==============================================================================
VERSION=$(cat /etc/version 2>/dev/null || echo "$INSTALLED_VERSION")
echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${NC}"
echo -e " ${C_BOLD}VERSION:${NC} ${C_CYAN}v${VERSION}${NC} │ ${C_BOLD}SCRIPT BY:${NC} ${C_GOLD}THE_S${NC} │ ${C_BOLD}CONTACT:${NC} ${C_GREEN}t.me/THE_S_NET${NC}"
echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${NC}"
echo ""

read -p " Select menu [00-99]🫴: " opt
echo -e ""

case $opt in
    1 | 01) clear ; ssh ;;
    2 | 02) clear ; vmess ;;
    3 | 03) clear ; vless ;;
    4 | 04) clear ; trojan ;;
    5 | 05) clear ; socks ;;
    6 | 06) clear ; zivpn ;;
    7 | 07) clear ; dns ;;
    8 | 08) clear ; domain ;;
    9 | 09) clear ; iptools ;;
    10) clear ; status ;;
    11) clear ; netguard ;;
    12) clear ; port ;;
    13) clear ; log ;;
    14) clear ; tgbot ;;
    15) clear ; uninstall ;;
    16) clear ; fastdns ;;
    18) clear ; web ;;
    88) reboot ;;
    99) clear ; update ;;
    0 | 00) exit 0 ;;
    *) clear ; exec "$0" ;;
esac
