import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  String rutaImagen =
      "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png";
  String imagenCargada = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Prueba de Cámara y Galería"),
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: () {
                    abrirSeleccionOrigen();
                  },
                  child: Text("Tomar Foto")),
              Container(
                margin:
                    EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    image: DecorationImage(
                        fit: BoxFit.cover, image: NetworkImage(rutaImagen))),
              )
            ],
          )),
    );
  }

  Future<void> abrirSeleccionOrigen() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
                child: Column(
              children: [
                GestureDetector(
                  child: Text("Cámara"),
                  onTap: () {
                    obtenerImagen(ImageSource.camera);
                  },
                ),
                Padding(padding: EdgeInsets.all(15)),
                GestureDetector(
                  child: Text("Galería"),
                  onTap: () {
                    obtenerImagen(ImageSource.gallery);
                  },
                ),
              ],
            )),
          );
        });
  }

  void obtenerImagen(ImageSource source) async {
    File image;

    var picture = await ImagePicker.platform.pickImage(source: source);

    if (picture != null) {
      image = File(picture.path);

      ImageResponse ir = await subirImagen(image);

      this.imagenCargada = ir.fileUploaded;

      if (imagenCargada != '') {
        setState(() {
          this.rutaImagen =
              "http://10.0.2.2:8282/obtenerimagen/" + imagenCargada;
          this.imagenCargada = '';
        });
      }
    }
  }

  Future<ImageResponse> subirImagen(File image) async {
    var request = http.MultipartRequest(
        "POST", Uri.parse("http://10.0.2.2:8282/subirimagen"));

    var picture = await http.MultipartFile.fromPath("imagen", image.path);

    request.files.add(picture);

    Position position = await obtenerPosicionGeografica();

    request.fields["longitud"] = position.longitude.toString();
    request.fields["latitud"] = position.latitude.toString();
    request.fields["altitud"] = position.altitude.toString();

    var response = await request.send();

    var responseData = await response.stream.toBytes();

    String rawResponse = utf8.decode(responseData);

    var jsonResponse = jsonDecode(rawResponse);

    print(rawResponse);

    ImageResponse ir = ImageResponse(jsonResponse);

    return ir;
  }

  Future<Position> obtenerPosicionGeografica() async {
    bool servicioHabilidado = await Geolocator.isLocationServiceEnabled();
    //GPS esta encendido

    if (servicioHabilidado) {
      LocationPermission permisos = await Geolocator.checkPermission();

      if (permisos == LocationPermission.denied ||
          permisos == LocationPermission.deniedForever) {
        permisos = await Geolocator.requestPermission();
      }

      if (permisos == LocationPermission.whileInUse ||
          permisos == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation);
        return position;
      }
    }

    return Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0);
  }
}

class ImageResponse {
  String fileUploaded = '';

  ImageResponse(Map jsonResponse) {
    this.fileUploaded = jsonResponse["fileUploaded"];
  }
}
