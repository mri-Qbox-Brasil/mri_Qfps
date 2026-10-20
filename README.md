# mri_Qfps

Menu de FPS para o jogador (F9 do mri_Qbox): presets de desempenho, ajuste fino de distância de renderização, luzes e sombras, filtros de timecycle e uma mira customizada desenhada na NUI. O dono do servidor ajusta tudo na aba **FPS** do mri_Qadmin, sem mexer em arquivo nem reiniciar.

## Recursos

- **Presets de FPS:** Padrão, Médio, Baixo e Ultra baixo (este também faz a limpeza de efeitos pesados).
- **Ajuste fino:** distância de renderização (LOD), luzes distantes e sombras.
- **Filtros gráficos:** cinco timecycles prontos.
- **Mira customizada:** tamanho, espessura, abertura, ponto central, cor, opacidade e contorno, com prévia ao vivo. Aparece só armado e mirando; o loop dorme fora de combate.
- **Preferências por jogador:** tudo fica salvo no cliente (KVP).
- **Tema da suíte:** `@mriqbox/ui-kit`, segue o `/uiconfig` e as cores da MRI ao vivo.

## Desenvolvimento

A fonte da NUI fica em `web/` e o build vai pra `html/`:

```
cd web
pnpm install
pnpm build
```

`pnpm dev` abre o menu no navegador com dados de exemplo; `?embedded=1` mostra a aba do mri_Qadmin.

Manual completo: [MANUAL.md](MANUAL.md).

## Licença

O código deste recurso é MIT com Commons Clause: pode usar, modificar e redistribuir à vontade, mas não pode vender, nem a versão original nem uma modificada. Texto completo em [LICENSE](LICENSE).

O som do hitmarker (`web/src/assets/hit.wav`) é CC0, de [freesound.org/s/570335](https://freesound.org/s/570335/).
