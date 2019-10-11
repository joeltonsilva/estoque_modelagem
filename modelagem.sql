#NÃO FAZER POIS TEM 'item'
CREATE TABLE `item` (
`item_id` INT(11) NOT NULL AUTO_INCREMENT,
`ativo` VARCHAR(1) NOT NULL DEFAULT 'S' COMMENT 'N - False(Não habilita) / S - True(habilita)',
`descricao` VARCHAR(60) NULL DEFAULT NULL,
`estoque_minimo` DECIMAL(10,5) NULL DEFAULT NULL,
`estoque_maximo` DECIMAL(10,5) NULL DEFAULT NULL,
PRIMARY KEY (`item_id`));

CREATE TABLE `entrada_produto` (
`id` INT(11) NOT NULL AUTO_INCREMENT,
`empresa_id` INT(11) NOT NULL,
`estoque_id` INT(11) NOT NULL,
`item_id` INT(11) NOT NULL,
`quantidade` DECIMAL(10,5) NOT NULL,
`data` DATE NOT NULL,
`valor_ent` DECIMAL(9,2) NULL DEFAULT '0.00' COMMENT 'O valor de entrada/saída sendo 0.00 alterará o último preço de custo/vendido',
`descricao` VARCHAR(100) NULL DEFAULT NULL,
PRIMARY KEY (`id`)) COMMENT='CONTROLE DE ESTOQUE - ENTRADA';

#JÁ CRIADO NO ERP
CREATE TABLE `estoque_cadastro` (#TABELA FICA RESTRITA, O IDENTIFICADOR DE ESTOQUE PRINCIPAL SOMENTE ADMNISTRADOR DO SISTEMA MECHE, NÃO PODE SER ALTERADO - NOME DO ESTOQUE(DEPÓSITO CENTRAL OU LOJA)
`estoque_id` INT(11) NOT NULL AUTO_INCREMENT,
`empresa_id` INT(11) NOT NULL,
`descricao` VARCHAR(60) NULL DEFAULT NULL,
`ativo` VARCHAR(1) NOT NULL DEFAULT 'S' COMMENT 'N - False(Não habilita) / S - True(habilita)',
`principal` INT(1) NOT NULL DEFAULT '0' COMMENT '0 - False(Não habilita) / 1 - True(habilita)',
PRIMARY KEY (`estoque_id`)) COMMENT='CONTROLE DE ESTOQUE - CADASTRO DO ESTOQUES # #TABELA FICA RESTRITA, O IDENTIFICADOR DE ESTOQUE PRINCIPAL SOMENTE ADMNISTRADOR DO SISTEMA MECHE, NÃO PODE SER ALTERADO - NOME DO ESTOQUE(DEPÓSITO CENTRAL OU LOJA';


CREATE TABLE `estoque` (
`id` INT(11) NOT NULL AUTO_INCREMENT,
`empresa_id` INT(11) NOT NULL,
`estoque_id` INT(11) NOT NULL,
`item_id` INT(11) NOT NULL,
`quantidade` DECIMAL(10,5) NOT NULL,
`valor_ent` DECIMAL(9,2) NULL DEFAULT '0.00',
`valor_sai` DECIMAL(9,2) NULL DEFAULT '0.00',
PRIMARY KEY (`id`)) COMMENT='CONTROLE DE ESTOQUE - O PRÓPRIO ESTOQUE';

CREATE TABLE `saida_produto` (
`id` INT(11) NOT NULL AUTO_INCREMENT,
`empresa_id` INT(11) NOT NULL,
`estoque_id` INT(11) NOT NULL,
`item_id` INT(11) NOT NULL,
`quantidade` DECIMAL(10,5) NOT NULL,
`data` DATE NOT NULL,
`valor_sai` DECIMAL(9,2) NULL DEFAULT '0.00' COMMENT 'O valor de entrada/saída sendo 0.00 alterará o último preço de custo/vendido',
`descricao` VARCHAR(100) NULL DEFAULT NULL,
PRIMARY KEY (`id`)) COMMENT='CONTROLE DE ESTOQUE - SAÍDA';




DELIMITER //
  CREATE PROCEDURE `SP_AtualizaEstoque`( `id_prod` int, `empres_id` int, `estoqu_id` int, `quantidade_comprada` decimal, valor_unit_entr decimal(9,2), valor_unit_sai decimal(9,2))
BEGIN
    declare contador int(11);
 
    SELECT count(*) into contador FROM estoque WHERE item_id = id_prod AND empresa_id = empres_id AND estoque_id = estoqu_id;
 
    IF contador > 0 THEN

            #ATUALIZAR SE TIVER NOVO VALOR DE ENTRADA, ATUALIZA VALOR DE ENTRADA, CASO CONTRÁRIO, VALOR DE SAÍDA
            IF valor_unit_entr > 0 THEN
                UPDATE estoque SET quantidade=quantidade + quantidade_comprada, valor_ent = valor_unit_entr
                WHERE item_id = id_prod AND empresa_id = empres_id AND estoque_id = estoqu_id;
            ELSE
                UPDATE estoque SET quantidade=quantidade + quantidade_comprada, valor_sai = valor_unit_sai
                WHERE item_id = id_prod AND empresa_id = empres_id AND estoque_id = estoqu_id;
            END IF;





    ELSE
        INSERT INTO estoque (item_id, empresa_id, estoque_id, quantidade, valor_ent, valor_sai) values (id_prod, empres_id, estoqu_id, quantidade_comprada, valor_unit_entr, valor_unit_sai);
    END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER `TRG_EntradaProduto_AI` AFTER INSERT ON `entrada_produto`
FOR EACH ROW
BEGIN
      CALL SP_AtualizaEstoque (new.item_id, new.empresa_id, new.estoque_id,new.quantidade, new.valor_ent, 0.00);
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER `TRG_EntradaProduto_AU` AFTER UPDATE ON `entrada_produto`
FOR EACH ROW
BEGIN
      CALL SP_AtualizaEstoque (new.item_id, new.empresa_id, new.estoque_id, new.quantidade - old.quantidade, new.valor_ent, 0.00);
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER `TRG_EntradaProduto_AD` AFTER DELETE ON `entrada_produto`
FOR EACH ROW
BEGIN
      CALL SP_AtualizaEstoque (old.item_id, old.empresa_id, old.estoque_id, old.quantidade * -1, old.valor_ent, 0.00);
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER `TRG_SaidaProduto_AI` AFTER INSERT ON `saida_produto`
FOR EACH ROW
BEGIN
      CALL SP_AtualizaEstoque (new.item_id, new.empresa_id, new.estoque_id, new.quantidade * -1, 0.00, new.valor_sai);
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER `TRG_SaidaProduto_AU` AFTER UPDATE ON `saida_produto`
FOR EACH ROW
BEGIN
      CALL SP_AtualizaEstoque (new.item_id, new.empresa_id, new.estoque_id, old.quantidade - new.quantidade, 0.00, new.valor_sai);
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER `TRG_SaidaProduto_AD` AFTER DELETE ON `saida_produto`
FOR EACH ROW
BEGIN
      CALL SP_AtualizaEstoque (old.item_id, old.empresa_id, old.estoque_id, old.quantidade, 0.00, old.valor_sai);
END //
DELIMITER ;













#=============================================================
#Ficaremos muito felizes caso você queira contribuir com os códigos para
#leitura e importação da NFe para base de dados, mas se o fizer tente ser
#o mais genérico possível. Use as classes PDO se possível.
#Mais um detalhe como deve ser o processo de inserção de NFe na base de
#dados :
#a) ler o xml
#b) verificar sua validade (com o xsd)
#c) verificar o protocolo na SEFAZ origem e comparar com o anexado a NFe
#d) verificar o digest (recalcular o digest) para garantir que não foi
#adulterada antes do envio
#e) se tudo estiver correto então grave na base (lembrando de alterar o
#CFOP)
#Roberto





