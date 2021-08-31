#INCLUDE "protheus.ch"
#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

user function LERARQVS()
    //Local aArea := SA2->(GetArea())
    Local cFile := ""
    Local nHandle := 0
    Local cLinha := ""
    Local lPrim := .T. //verifica se e a primeira linha
    Local aCampos := {}
    Local aDados := {}
    Local nCounti
    Local nCountj

    //Seleciona o arquivo -> cGetFile apresenta uma tela com diretorios disponiveis
    cFile := cGetFile("Files CSV|*.csv", "Select csv File",0, ,.F., GETF_LOCALHARD, .T., .T.)

    //Abre o arquivo de texto e disponibiliza as funcoes FT_F*
    nHandle := FT_FUSE(cFile) //em caso de falha, retorna -1

    //Em caso de erro, aborta operacao
    If nHandle == -1
        Return Nil
    Endif

    //Posiciona na primeira linha
    FT_FGOTOP()

    //Le o arquivo enquanto nao for o final dele
    While !FT_FEOF()
        cLinha := FwNoAccent(FT_FREADLN()) //le a linha no arquivo e remove os acentos
        cLinha := UPPER(cLinha) //transforma o arquivo inteiro para caixa alta

        If lPrim //verifica se esta na primeira linha (campos)
            aCampos := Separa(cLinha, ";", .T.) //quebra o arquivo nas ';'
            lPrim = .F. //seta como falso a primeira linha
        Else //nao esta na primeira linha (dados)
            AADD(aDados, Separa(cLinha, ";", .T.))
        EndIf
    
        //avanca para proxima linha
        FT_FSKIP()
    ENDDO

    //Mensagem no appserver
    ConOut("Arquivos lidos... Adicionando-os a tabela SA2...")
    
    //Libera arquivo
    FT_FUSE()

    Begin Transaction
        For nCounti := 1 To len(aDados)
            DbSelectArea("SA2") //abre a tabela em parametro
            SA2->(DbSetOrder(1)) //seleciona o primeiro indice
            SA2->(DbGoTop()) //vai para o topo da tabela

            //dbseek faz a varredura na tabela e impede inclusao de registros ja existentes
            If !dbSeek(xFilial("SA2")+aDados[nCounti, 1]+aDados[nCounti,2])
                RecLock("SA2", .T.) //.F. trava a tabela para alteracao, .T. para inclusao
                SA2->A2_FILIAL := xFilial("SA2")
                For nCountj := 1 to len(aCampos)
                    cCampo := "SA2->" + aCampos[nCountj] //faz o apontamento nos cabecalhos
                    &cCampo := aDados[nCounti, nCountj]
                Next nCountj
                SA2->(MsUnlock()) //destrava a tabela
            EndIF
        Next nCounti
    End Transaction

    MsgInfo("Importação concluída com sucesso!", "ATENÇÃO")

Return
