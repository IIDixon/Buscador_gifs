import 'dart:convert';
import 'package:buscador_gifs/pages/gif_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';
import 'package:transparent_image/transparent_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  String? _search; // String que será utilizada na busca de gifs
  final _trending = "https://api.giphy.com/v1/gifs/trending?api_key=jJcUupVvXijBT74X2xdUK7z9fQQSRzfX&limit=20&rating=g"; // URL da API com os top's 20 gifs
  int _offSet = 0; // Contador que será utilizado nas buscas
  
  Future<Map>_getSearch() async{ // Função de busca da API
    http.Response response; // Resposta da API
    
    if(_search == null || _search!.isEmpty){ // Caso o textfield esteja vazio, irá retornar os top's 20 gifs
      response = await http.get(Uri.parse(_trending)); // Atribui o retorno da busca a resposta da API
    }
    else{
      response = await http.get(Uri.parse("https://api.giphy.com/v1/gifs/search?api_key=jJcUupVvXijBT74X2xdUK7z9fQQSRzfX&q=$_search&limit=19&offset=$_offSet&rating=g&lang=pt")); // Atribui o retorno da busca a resposta da API
    }

    return json.decode(response.body); // Converte o retorna da busca em formato JSON
  }                                    // e o retorna como resposta na função _getSearch

  @override
  void initState(){
    super.initState();
    _getSearch().then((map) {
      print(map);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Image.network("https://developers.giphy.com/static/img/dev-logo-lg.gif"), // Atribui na appBar o gif do link especificado
        centerTitle: true, // Centraliza o conteúdo da appBar
      ),
      backgroundColor: Colors.black, // Define a cor de fundo da Appbar
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onSubmitted: (text){ // Função chamada ao clicar no botão "Confirmar" do teclado
                setState(() {
                  _search = text; // Atribui o texto digitado a variável que será utilizada para busca da API
                  _offSet = 0;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Pesquise aqui',
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20
                ),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                  )
                )
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FutureBuilder( // Cria um widget com construtor futuro
              future: _getSearch(), // Indica que o futuro que será construído depende do retorno da função _getSearch
              builder: (context, snapshot) {
                switch(snapshot.connectionState){
                  case ConnectionState.waiting: // Caso esteja aguardando o retorno
                  case ConnectionState.none: // Caso esteja com retorno vazio
                    return Container(
                      width: 200,
                      height: 200,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator( // Circulo
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Retorna um circulo animado
                        strokeWidth: 5, // Espessura do circulo
                      ),
                    );
                  default:
                    if(snapshot.hasError){
                      return Container(); // Caso houver erro na busca, retornará um container vazio
                    }
                    else{
                      return _CreateGifTable(context,snapshot); // Quando concluir a busca, será construído o corpo com os gifs
                    }
                }
              }),
            ),
        ],
      ),
    );
  }

  int _getCount(List data){
    if(_search == null || _search!.isEmpty){ // Caso o textfield esteja vazio, será retornado a quantidade de gifs buscados
      return data.length;
    } else{ // Caso esteja preenchido, será retornado a quantidade de gifs buscados +1, para que adicionemos o botão para carregar mais gifs
      return data.length + 1;
    }
  }

  Widget _CreateGifTable(BuildContext context, AsyncSnapshot snapshot){
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( // Formato do grid onde ficará os gifs
        crossAxisCount: 2, // Qtd de gifs por linha
        crossAxisSpacing: 10, // Espaçamento entre os gifs
        mainAxisSpacing: 10, // Espaçamento entre os gifs e a lateral
      ),
      itemCount: _getCount(snapshot.data!["data"]), // Qnt de itens a serem alocados no grid
      itemBuilder: (context,index){ // Constrói o grid com os itens
        if( _search == null || index < snapshot.data!["data"].length){ // Caso o textfield esteja preenchido e o indice atual seja menor que a quantidade de gifs
          return GestureDetector(
            onLongPress: (){
              Share.share(snapshot.data!["data"][index]["images"]["fixed_height"]["url"]); // Função para compartilhar o gifs ao clicar e segurar
            },
            onTap: (){
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => GifPage(gifData: snapshot.data!["data"][index])), // Função que mostrará o gifs em outra tela ao clicar
              );
            },
            child: FadeInImage.memoryNetwork( // Função para aparição suave da imagem no carregamento
                placeholder: kTransparentImage, // Enquanto não carrega, será mostrado uma imagem transparente no lugar
                image: snapshot.data!["data"][index]["images"]["fixed_height"]["url"], // Atribui a imagem carregada
                height: 300, // Define o tamanho do bloco
                fit: BoxFit.cover, // Faz com que o gif se ajuste ao tamanho do bloco, de forma que preencha totalmente
            ),
          );
        } else{ // Quando acabar de carregar todos os gifs buscados, será criado um botão para carregar mais gifs
          return Container(
            child: GestureDetector( // Ao clicar no botão, define o offset para +19, sendo assim serão listados outros 19 gifs
              onTap: (){            // offset no caso desta APÍ, pode ser definido como o ID de cada GIF, inicialmete buscamos os gifs a partir do ID 0,
                setState(() {       // e ao clicar em carregar mais, iremos buscar gifs a partir do ID 19, assim sempre será carregado gifs diferentes
                  _offSet += 19; // Define o offset para 19, sendo assim, serão buscados outros 19 gifs ao clicar, e assim por diante
                });
              },
              child: Column( // Cria o botão para carregar mais gifs
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, color: Colors.white, size: 70,),
                  Text("Carregar Mais...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  )
                ],
              ),
            ),
          );
        }
      }
    );
  }
}
