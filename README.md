# PONTIFÍCIA UNIVERSIDADE CATÓLICA DO RIO GRANDE DO SUL
## ESCOLA POLITÉCNICA
## SISTEMAS DIGITAIS - 2026/1

## TRABALHO 3
### Estudantes:
Alexandre Utzig do Amaral Padilha, 
Giovanni Camargo Gardenal Morandi, 
Henrique Skolaude Staubus, 
Solano Schmidt Battisti

### Estrutura do Projeto
```
rtl/
    emulador_sensor.sv 
    memoria.sv
    coletor_dados.sv
    top.sv
tb/
    tb_top.sv
sim.do
README.md
```


### Execução do Trabalho
Dentro do diretório, digitar `do sim.do` no terminal do Questa

### Resultados
No terminal do Questa, aparecerá a coleta de cada um dos registradores de cada sensor (mostrando o que foi escrito na memória), e depois comparando com o esperado (pego direto dos registradores).

Para um dado registrador x do sensor 0, por exemplo, a coleta e verificação aparecerão como algo assim:
```
[MEM] Escrevendo 0xNN no endereço x da memória

[TB] PASS! Sensor 0 reg[x]: Esperado=0xNN Encontrado=0xNN
ou
[TB] FAIL! Sensor 0 reg[x]: Esperado=0xYY Encontrado=0xNN
```
