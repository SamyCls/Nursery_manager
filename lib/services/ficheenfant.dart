import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '/models/enfant.dart';
import '/models/accompagnateur.dart';
import 'package:open_filex/open_filex.dart';

class PDFFillService {
  static Future<void> fillAndSaveChildForm(
      Enfant enfant, List<Accompagnateur> accompagnateurs) async {
    // Load the background image
    final ByteData imageData = await rootBundle.load('assets/pdf/ficheenfant.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final bgImage = pw.MemoryImage(imageBytes);

    // Load the PDF document
    final pdf = pw.Document();

    // Add the page with template and overlay
pdf.addPage(
  pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero, // ✅ removes default white margins
    build: (pw.Context context) {
      return pw.Stack(
        children: [
          pw.SizedBox(
            width: PdfPageFormat.a4.width,
            height: PdfPageFormat.a4.height,
            child: pw.Image(bgImage, fit: pw.BoxFit.fill),
          ),
              
              // Overlay with text fields - adjust coordinates as needed
              pw.Positioned(
                left: 281,  // X coordinate for Nom
                top: 211,   // Y coordinate for Nom
                child: pw.Text(enfant.nom, style: pw.TextStyle(fontSize: 15)),
              ),
              
              pw.Positioned(
                left: 305,  // X coordinate for Prénom
                top: 235,   // Y coordinate for Prénom
                child: pw.Text(enfant.prenom, style: pw.TextStyle(fontSize: 15)),
              ),
              
              pw.Positioned(
                left: 375,  // X coordinate for Date de naissance
                top: 260,   // Y coordinate for Date de naissance
                child: pw.Text(enfant.dateNaissance ?? '', style: pw.TextStyle(fontSize: 15)),
              ),
              
              pw.Positioned(
                left: 279,  // X coordinate for Sexe
                top: 285,   // Y coordinate for Sexe
                child: pw.Text(enfant.sexe ?? '', style: pw.TextStyle(fontSize: 15)),
              ),
              
              pw.Positioned(
                left: 307,  // X coordinate for Adresse
                top: 313,   // Y coordinate for Adresse
                child: pw.Text(enfant.adresse ?? '', style: pw.TextStyle(fontSize: 15)),
              ),
              
              // Add father's information
              pw.Positioned(
                left: 182,  // X coordinate for Père Nom&prénom
                top: 406,   // Y coordinate for Père Nom&prénom
                child: pw.Text(enfant.nomPrenomPere ?? '', style: pw.TextStyle(fontSize: 12)),
              ),
              
              pw.Positioned(
                left: 165,  // X coordinate for Père Téléphone
                top: 428,   // Y coordinate for Père Téléphone
                child: pw.Text(enfant.telPere ?? '', style: pw.TextStyle(fontSize: 12)),
              ),
              
              pw.Positioned(
                left: 165,  // X coordinate for Père Profession
                top: 448,   // Y coordinate for Père Profession
                child: pw.Text(enfant.professionPere ?? '', style: pw.TextStyle(fontSize: 12)),
              ),
              
              // Add mother's information
              pw.Positioned(
                left: 404,  // X coordinate for Mère Nom&prénom
                top: 464,   // Y coordinate for Mère Nom&prénom
                child: pw.Text(enfant.nomPrenomMere ?? '', style: pw.TextStyle(fontSize: 12)),
              ),
              
              pw.Positioned(
                left: 387,  // X coordinate for Mère Téléphone
                top: 484,   // Y coordinate for Mère Téléphone
                child: pw.Text(enfant.telMere ?? '', style: pw.TextStyle(fontSize: 12)),
              ),
              
              pw.Positioned(
                left: 380,  // X coordinate for Mère Profession
                top: 504,   // Y coordinate for Mère Profession
                child: pw.Text(enfant.professionMere ?? '', style: pw.TextStyle(fontSize: 12)),
              ),
              
              // Add family status
              pw.Positioned(
                left: 300,  // X coordinate for Statut familial
                top: 542,   // Y coordinate for Statut familial
                child: pw.Text(enfant.statutFamilial ?? '', style: pw.TextStyle(fontSize: 12)),
              ),
              
              // Add accompagnateurs if available
              if (accompagnateurs.isNotEmpty) ...[
                pw.Positioned(
                  left: 215,  // X coordinate for Accompagnateur 1
                  top: 643,   // Y coordinate for Accompagnateur 1
                  child: pw.Text(accompagnateurs[0].nomPrenom, style: pw.TextStyle(fontSize: 12)),
                ),
                
                pw.Positioned(
                  left: 197,  // X coordinate for Accompagnateur 1 Téléphone
                  top: 666,   // Y coordinate for Accompagnateur 1 Téléphone
                  child: pw.Text(accompagnateurs[0].telephone, style: pw.TextStyle(fontSize: 12)),
                ),
                
                pw.Positioned(
                  left: 155,  // X coordinate for Accompagnateur 1 CIN
                  top: 689,   // Y coordinate for Accompagnateur 1 CIN
                  child: pw.Text(accompagnateurs[0].cin, style: pw.TextStyle(fontSize: 11)),
                ),
              ],
              
              if (accompagnateurs.length > 1) ...[
                pw.Positioned(
                  left: 392,  // X coordinate for Accompagnateur 2
                  top: 643,   // Y coordinate for Accompagnateur 2
                  child: pw.Text(accompagnateurs[1].nomPrenom, style: pw.TextStyle(fontSize: 12)),
                ),
                
                pw.Positioned(
                  left: 375,  // X coordinate for Accompagnateur 2 Téléphone
                  top: 666,   // Y coordinate for Accompagnateur 2 Téléphone
                  child: pw.Text(accompagnateurs[1].telephone, style: pw.TextStyle(fontSize: 12)),
                ),
                
                pw.Positioned(
                  left: 330,  // X coordinate for Accompagnateur 2 CIN
                  top: 689,   // Y coordinate for Accompagnateur 2 CIN
                  child: pw.Text(accompagnateurs[1].cin, style: pw.TextStyle(fontSize: 11)),
                ),
              ],
            ],
          );
        },
      ),
    );

    // Save the PDF to device storage and open it
    final directory = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${directory.path}/fiche_enfant_${enfant.nom}_${enfant.prenom}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    
    // Save the PDF
    final Uint8List bytes = await pdf.save();
    await outputFile.writeAsBytes(bytes);

    // Open the file directly
    await OpenFilex.open(outputFile.path);
  }
}