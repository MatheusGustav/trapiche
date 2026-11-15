# Trapiche

Dock com widgets ao vivo para o KDE Plasma 6. É um plasmoide: fica dentro de um painel do Plasma e mostra uma fileira de blocos (bateria, apps, pasta, música, clima e outros).

## Instalar

```sh
kpackagetool6 -t Plasma/Applet -i package    # primeira vez
kpackagetool6 -t Plasma/Applet -u package    # atualizar
```

Depois, crie um painel vazio no Plasma e adicione o widget "Trapiche" a ele. A dock troca o fundo do painel por uma barra de vidro que cobre o painel inteiro, então outros widgets do Plasma (a bandeja do sistema, por exemplo) podem ficar no mesmo painel. O desfoque atrás do vidro é o do próprio Plasma: o painel precisa estar com opacidade "translúcida". A altura do painel define o tamanho dos blocos (o desenho foi feito para 77 px). Painel vertical não é suportado.

Os widgets e as opções de cada um são escolhidos em "Configurar Trapiche". A "Pasta de aplicativos" pode entrar várias vezes na dock; os aplicativos de cada uma são escolhidos na aba "Opções".

## Dependências

Além do Plasma 6: `qdbus-qt6`, `wpctl`, `nmcli`, `bluetoothctl` e `kioclient`, usados pelos widgets de brilho, áudio, rede e lixeira.

O widget Pasta abre um pequeno gerenciador de arquivos e usa `python3`, `gio` (lixeira) e `wl-copy`/`wl-paste` (copiar e colar arquivos com outros programas). A ordem de cada pasta, inclusive a arrumação feita arrastando, fica em `~/.local/share/trapiche/pastas.json`.

Clima, criptomoeda, câmbio e ações consultam serviços públicos pela internet (Open-Meteo, Binance, open.er-api.com e Yahoo Finance).

Os widgets do GitHub usam o login do `gh` (`gh auth login`). Os do Claude Code usam `python3`. O modelo mais usado sai dos registros locais (`~/.claude/projects`). As porcentagens do plano chegam pela linha de status do Claude Code, que precisa apontar para o script do pacote em `~/.claude/settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "python3 ~/.local/share/plasma/plasmoids/io.github.matheusgustav.trapiche/contents/code/linha-de-status.py"
}
```

O script grava os limites em `~/.cache/trapiche` e não imprime nada. Os números só mudam enquanto o Claude Code está aberto; se o Trapiche for desinstalado, essa entrada precisa sair do `settings.json`.

## Desenvolvimento

`dev/foto.sh saida.png` roda o plasmoide num compositor virtual, fora da tela e com configuração descartável, e salva uma foto. As variáveis `WIDGETS`, `OPCOES`, `DADOS` e `ABRIR` montam o cenário.

O catálogo de widgets fica em `package/contents/ui/catalogo.js`; cada widget é um arquivo em `package/contents/ui/widgets/`.
