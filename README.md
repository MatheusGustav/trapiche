# Trapiche

Dock com widgets ao vivo para o KDE Plasma 6. É um plasmoide: fica dentro de um painel do Plasma e mostra uma fileira de blocos (bateria, apps, pasta, música, clima e outros).

## Instalar

```sh
kpackagetool6 -t Plasma/Applet -i package    # primeira vez
kpackagetool6 -t Plasma/Applet -u package    # atualizar
```

Depois, crie um painel vazio no Plasma e adicione o widget "Trapiche" a ele. A altura do painel define o tamanho dos blocos (o desenho foi feito para 77 px). Painel vertical não é suportado.

Os widgets e as opções de cada um são escolhidos em "Configurar Trapiche".

## Dependências

Além do Plasma 6: `qdbus-qt6`, `wpctl`, `nmcli`, `bluetoothctl` e `kioclient`, usados pelos widgets de brilho, áudio, rede e lixeira.

Clima, criptomoeda, câmbio e ações consultam serviços públicos pela internet (Open-Meteo, Binance, open.er-api.com e Yahoo Finance).

## Desenvolvimento

`dev/foto.sh saida.png` roda o plasmoide num compositor virtual, fora da tela e com configuração descartável, e salva uma foto. As variáveis `WIDGETS`, `OPCOES`, `DADOS` e `ABRIR` montam o cenário.

O catálogo de widgets fica em `package/contents/ui/catalogo.js`; cada widget é um arquivo em `package/contents/ui/widgets/`.
