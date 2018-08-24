//pragma experimental ABIEncoderV2;
pragma solidity ^0.4.0;

contract Fundo{
    
    struct Carteira {
        uint fundoTotal;
        uint dataAbertura;
        ValorPago[] valoresPagos;
    }
    
    struct ValorPago {
        uint valor;
        uint dataPagamento;
        uint rendimento; 
    }
    
    // Seguradora administradora do fundo
    address seguradora;
    address[] responsaveis;
    
    // Dicionario de fundos que associam o fundo a carteira do cliente
    mapping(address => Carteira) carteira;
    mapping(address => bool) isClient;
    address[] clientes;
    
    
    constructor(address _seguradora) public {
       seguradora = _seguradora;
    }
    
    /* MODIFIERS */
    modifier isSeguradora {
        require(msg.sender == seguradora, "carteira não cadastrada como seguradora");
        _;
    }
    
    modifier isNovoCliente(address _cliente) {
        require(isClient[_cliente] == false, "cliente ja existente");
        _;
    }
    
    modifier isCliente(address _cliente) {
        require(msg.sender == _cliente, "cliente nao cadastrado!");
        _;
    }
    
    modifier passadoUmAno(address _cliente) {
        require(now >= (carteira[_cliente].dataAbertura + 365 days), "ainda nao passou 1 ano");
        _;
    }
    
    modifier isClienteOrSeguradora (address _cliente) {
        require((msg.sender == _cliente) || msg.sender == seguradora);
        _;
    }
    
    /* Eventos */
    event clienteAdicionado(address _cliente);
    event clientePagouFundo(address _cliente, uint _valorPago);
    event clienteSolicitouFundo(address _cliente, uint _valorSolicitado);
   
    
    /* Funções */
    function adicionaCliente(address _novoCliente) public isSeguradora isNovoCliente(_novoCliente) {
        // adiciona timestamp do bloco de abertura de conta
        carteira[_novoCliente].dataAbertura = now;
        // inicia valor do fundo da carteira como 0
        carteira[_novoCliente].fundoTotal = 0;
        // atribui verdadeiro a carteira do cliente para evitar nova abertura de conta
        isClient[_novoCliente] = true;
        // adiciona cliente a lista de enderecos dos clientes
        clientes.push(_novoCliente);
        emit clienteAdicionado(_novoCliente);
    }
    
    
    function pagarMensalidade() public payable isCliente(msg.sender) returns(uint){
        // Cliente transfere para a seguradora
        msg.sender.transfer(msg.value);
        // cria objeto valor pago com base no valor transmitido pela transacao
        ValorPago memory valor = ValorPago({ valor: msg.value, dataPagamento: now, rendimento: 0 });
        // insere o valor na lista de valores valoresPagos
        carteira[msg.sender].valoresPagos.push(valor);
        // soma valor ao fundoTotal
        carteira[msg.sender].fundoTotal += msg.value;
        emit clientePagouFundo(msg.sender,msg.value);
        //retorna o fundo total apos a transferencia 
        return carteira[msg.sender].fundoTotal;
    }
    
    //ok
    function calcularRentabilidade(address _cliente) private isSeguradora(){
        // percorre a lista de pagamentos feitos
        for(uint pgto = 0; pgto < carteira[_cliente].valoresPagos.length; pgto++ ){
            // se o pagamento feito ja teve algum rendimento
            if(carteira[_cliente].valoresPagos[pgto].rendimento > 0) {
                // reajusta 1/100 sobre o valor rendido anteriormente
                carteira[_cliente].valoresPagos[pgto].rendimento += carteira[_cliente].valoresPagos[pgto].rendimento / 100; 
            }
            // reajusta em 1/100 o rendimento sobre o valor pago
            carteira[_cliente].valoresPagos[pgto].rendimento += carteira[_cliente].valoresPagos[pgto].valor / 100;
            // soma o rendimento ao fundo total da carteira
            carteira[_cliente].fundoTotal += carteira[_cliente].valoresPagos[pgto].rendimento;
        }
    }
    
    function rentabilizarCarteiraClientes() public payable {
        // percorrer lista de clientes e executar calcularRentabilidade()
        for(uint cliente = 0; cliente < clientes.length; cliente++) {
            calcularRentabilidade(clientes[cliente]);
        }
    }
    
    function verSaldo() public view isCliente(msg.sender) returns(uint) {
       return carteira[msg.sender].fundoTotal;
    }

    function consultaSaldo(address _cliente) public view isClienteOrSeguradora(_cliente) returns(uint) {
       return carteira[_cliente].fundoTotal;
    }
    
    function obterClientes() public view isSeguradora returns(address[]) {
        return clientes;
    }
    
    function solicitarFundo(uint _valorSolicitado) public isCliente(msg.sender) passadoUmAno(msg.sender){
        emit clienteSolicitouFundo(msg.sender, _valorSolicitado);
    }
    
    function transferirFundo(address _cliente, uint _valorSolicitado) public payable isSeguradora() passadoUmAno(_cliente) {
        // Transferir fundo para a carteira do cliente
        // responsaveis aprovam a transferencia do fundo
        require(_valorSolicitado <= carteira[_cliente].fundoTotal);
        _cliente.transfer(_valorSolicitado);
    }
    
    // funcao lanca warning por nao inicializacao, problema ao inicializar
    // function verRendimentos() public isCliente(msg.sender) returns(uint[],uint[]) {
    //     uint[] storage valoresPagos;
    //     uint[] storage rendimentos;
    //     for(uint pgto = 0; pgto < carteira[msg.sender].valoresPagos.length; pgto++ ){
    //         valoresPagos.push(carteira[msg.sender].valoresPagos[pgto].valor);
    //         rendimentos.push(carteira[msg.sender].valoresPagos[pgto].rendimento);
    //     }
    //     return (valoresPagos,rendimentos);
    // }
}
