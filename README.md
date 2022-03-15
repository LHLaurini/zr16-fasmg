# zr16-fasmg
zr16-fasmg permite utilizar flat assembler g para montar códigos assembly para o microcontrolador brasileiro ZR16S08.

## Vantagens sobre o assembler provido no SDK
- Permite a utilização de macros mais complexas (até recursivas, se desejado);
- Não há limite de tamanho de nomes de macros e constantes;
- Permite caracteres acentuados;
- Instruções podem receber expressões algébricas constantes diretamente (ex. `mov r0, 1+1`);
- Pode ser usado com mais facilidade em sistemas não-NT, como Linux;
- Gera arquivo MNE mantendo constantes;
- Suporta diretivas `include` e `file`.

## Utilização

1. Baixe o arquivo contendo o código-fonte e binários do flat assembler g em https://flatassembler.net/download.php. O flat assembler clássico pode funcionar também, mas não foi testado.
2. Extraia o conteúdo do arquivo no local desejado (por exemplo, "C:\fasmg" ou "/home/user/fasmg"). Caso não existam binários pré-compilados para a sua plataforma, estes podem ser compilados utilizando o fasm clássico.
3. Clone esse repositório (ou simplesmente baixe e extraia) na mesma pasta do código a ser compilado. Se um repositório git estiver sendo utilizado, é recomendado adicionar zr16-fasmg como submódulo.
4. Insira o código

        include "zr16-fasmg/zr16.asm"  
    para poder usar as macroinstruções do zr16-fasmg.

5. Após todas as instruções, utilize o código

        org 0x3ff
        dw 0xffff
    para que o arquivo seja preenchido de modo a ter 1024 words.

6. Inclua o local para o qual o fasmg foi instalado na variável de ambiente `PATH`. Pode ser necessário fazer login novamente.

### Pela linha de comando

7. Utilize os comandos

        fasmg arquivo.zr16 arquivo.zr16.bin
        fasmg -i mne=1 arquivo.zr16 arquivo.zr16.mne

    para gerar o binário final e o arquivo de instruções "mne", respectivamente.

### Pelo simulador

7. Em "Config Environment", guia "General", em "ASM Compiler Location" insira o caminho para o arquivo "build.bat".

## Alterações necessárias em códigos existentes

- São necessários os itens 4 e 5 da seção anterior;
- Acessos a memória e periféricos precisam usar colchetes `[]` ao invés de parênteses `()`;  
  Isso permite diferenciar, por exemplo, `(1+1)` e `[1+1]`, onde o primeiro é uma expressão que é igual a `2` e o segundo é uma referência à memória no endereço `0x002`.
- Constantes na memória de programa (diretiva `DC`) têm uma sintaxe diferente:

        constante1 dw 0x1234            ; 12 34
        constante2 dw 0x8764, 0x3210    ; 87 64 32 10

  O rótulo presente antes da diretiva `dw` pode ser usado em instruções.  
  Além de `dw`, que escreve words de 16 bits, existem as diretivas equivalentes a outros tamanhos: `db` (byte, 8 bits), `dd` (double word, 32 bits), `dp` (pword, 48 bits), `dq` (quadruple word, 64 bits), `dt` (ten bytes, 80 bits), `ddq` (double quadruple word, 128 bits), `dqq` (quadruple quadruple word, 256 bits) e `ddqq` (double quadruple quadruple word, 512 bits). A diretiva `emit` ainda não é suportada.

- Diretivas como `DV`, `DR` e `DA` podem todas ser omitidas.  
  Exemplo: ao invés de

        dr registrador = r1 
        dv variável_que_na_verdade_é_constante = 5

  use

        registrador = r1 
        variável_que_na_verdade_é_constante = 5
- Valores binários, como `0b1000101`, precisam ser escritos no formato `1000101b`;

## Problemas que ainda precisam ser resolvidos

### Erros em instruções dentro de macros são relativamente difíceis de encontrar
A maioria dos erros, no momento, é fácilmente compreendida. Por exemplo, a instrução `mov r0, 256` gera

    flat assembler  version g.ij2b8
    teste.zr16 [23]:
            mov r0, 256
    macro mov [59] macro assert_range [2]
    Custom error: valor fora da faixa permitida.

e a instrução `mov r1, 255` gera

    flat assembler  version g.ij2b8
    teste.zr16 [23]:
            mov r1, 255
    macro mov [62]
    Custom error: argumento inválido.

e em ambos casos é fácil de ver que o erro está ná linha 23 do arquivo teste.zr16. Já quando o erro é dentro de uma macro, mesmo que simples, como

    macro uma_macro
        mov r1, [0x00]
    end macro
    
        uma_macro

o erro resultante será

    flat assembler  version g.ij2b8
    teste.zr16 [27]:
            uma_macro
    macro uma_macro [1] macro mov [42]
    Custom error: argumento inválido.

ou seja, sabemos que o erro "argumento inválido" está uma instrução `mov` dentro da macro `uma_macro`, mas o erro não informa qual, forçando o programador a procurar o erro em todas as instruções `mov` usadas pela macro. No exemplo, é fácil encontrar o erro, mas em uma macro grande, com dezenas (ou até centenas) de instruções, esse processo pode demorar.  
Desse modo, é recomendado usar subrotinas ao invés de macros quando esta tornar-se muito grande.
