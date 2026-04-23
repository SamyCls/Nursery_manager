import '/models/enfant.dart';
import '/models/employe.dart';
import '../models/activity.dart';
import 'package:flutter/material.dart';
import '/models/depenses.dart';
import '/models/utilisateurs.dart';

final List<Enfant> dummyEnfants = <Enfant>[
  Enfant(
    id: 'E001',
    nom: 'Ali',
    prenom: 'Yacine',
    classe: 'Petite section',
    telephone: '0550123456',
    estActif: true,
    dateNaissance: '2018-03-12',
    sexe: 'Masculin',
    adresse: 'Alger Centre',
    nomPrenomPere: 'Mohamed Ali',
    telPere: '0550667788',
    professionPere: 'Médecin',
    adressePere: 'Alger',
    nomPrenomMere: 'Samira Haddad',
    telMere: '0560123456',
    professionMere: 'Enseignante',
    statutFamilial: 'Mariés',
   
    allergies: 'Aucune',
    commentairesMedicaux: 'RAS',
    historiquePresence: {
      DateTime(2025, 8, 1): "Absent",
      DateTime(2025, 8, 2): "Absent",
      DateTime(2025, 8, 3): "Présent",
      DateTime(2025, 8, 4): "Absent",
    },
  ),
  Enfant(
    id: 'E002',
    nom: 'Sara',
    prenom: 'Boudiaf',
    classe: 'Moyenne section',
    telephone: '0550876543',
    estActif: true,
    dateNaissance: '2017-11-25',
    sexe: 'Féminin',
    adresse: 'El Harrach',
    nomPrenomPere: 'Karim Boudiaf',
    telPere: '0550331122',
    professionPere: 'Ingénieur',
    adressePere: 'El Harrach',
    nomPrenomMere: 'Lamia Sahraoui',
    telMere: '0550771122',
    professionMere: 'Pharmacienne',
    statutFamilial: 'Mariés',
   
    allergies: 'Pollen',
    commentairesMedicaux: 'Utilise un spray en cas de crise',
    historiquePresence: {
      DateTime(2025, 8, 1): "Présent",
      DateTime(2025, 8, 2): "Présent",
      DateTime(2025, 8, 3): "Absent",
      DateTime(2025, 8, 4): "Présent",
    },
  ),
  Enfant(
    id: 'E003',
    nom: 'Nour',
    prenom: 'Belkacem',
    classe: 'Grande section',
    telephone: '0560456712',
    estActif: false,
    dateNaissance: '2016-07-02',
    sexe: 'Féminin',
    adresse: 'Bab Ezzouar',
    nomPrenomPere: 'Riad Belkacem',
    telPere: '0550123499',
    professionPere: 'Comptable',
    adressePere: 'Bab Ezzouar',
    nomPrenomMere: 'Souad Merah',
    telMere: '0560112299',
    professionMere: 'Coiffeuse',
    statutFamilial: 'Divorcés',
    
    allergies: 'Lait',
    commentairesMedicaux: 'Doit éviter les produits laitiers',
    historiquePresence: {
      DateTime(2025, 8, 1): "Présent",
      DateTime(2025, 8, 2): "Présent",
      DateTime(2025, 8, 3): "Présent",
      DateTime(2025, 8, 4): "Présent",
    },
  ),
  Enfant(
    id: 'E004',
    nom: 'Adam',
    prenom: 'Kherchi',
    classe: 'Petite section',
    telephone: '0550890912',
    estActif: true,
    dateNaissance: '2018-01-09',
    sexe: 'Masculin',
    adresse: 'Bir Mourad Raïs',
    nomPrenomPere: 'Nassim Kherchi',
    telPere: '0550234567',
    professionPere: 'Chef cuisinier',
    adressePere: 'Bir Mourad Raïs',
    nomPrenomMere: 'Meriem Fekir',
    telMere: '0560234567',
    professionMere: 'Architecte',
    statutFamilial: 'Mariés',

    allergies: 'Aucune',
    commentairesMedicaux: '',
    historiquePresence: {
      DateTime(2025, 8, 1): "Présent",
      DateTime(2025, 8, 2): "Absent",
      DateTime(2025, 8, 3): "Présent",
      DateTime(2025, 8, 4): "Absent",
    },
     paiements: [
      Paiement(
        date: DateTime(2025, 7, 10),
        mois: 'Juillet 2025',
        montantPaye: 2500,
        reste: 2500,
        montantdu: 5000,

        statut: StatutPaiements.partiel,
      ),
      Paiement(
        date: DateTime(2025, 6, 10),
        mois: 'Juin 2025',
        montantPaye: 5000,
        montantdu: 5000,
        reste: 0,
        statut: StatutPaiements.paye,
      ),
    ],
  ),
  Enfant(
    id: 'E005',
    nom: 'Lina',
    prenom: 'Zeroual',
    classe: 'Moyenne section',
    telephone: '0560223344',
    estActif: true,
    dateNaissance: '2017-05-15',
    sexe: 'Féminin',
    adresse: 'Kouba',
    nomPrenomPere: 'Anis Zeroual',
    telPere: '0550112233',
    professionPere: 'Professeur',
    adressePere: 'Kouba',
    nomPrenomMere: 'Houda Laid',
    telMere: '0560345678',
    professionMere: 'Avocate',
    statutFamilial: 'Mariés',
 
    allergies: '',
    commentairesMedicaux: 'RAS',
    historiquePresence: {
      DateTime(2025, 8, 1): "Absent",
      DateTime(2025, 8, 2): "Présent",
      DateTime(2025, 8, 3): "Présent",
      DateTime(2025, 8, 4): "Présent",
    },
  ),





  Enfant(
    id: '1',
    nom: 'Boukhalfa',
    prenom: 'Yasmine',
    classe: 'Petite section',
    telephone: '0555123456',
    estActif: true,
    dateNaissance: '2019-06-15',
    sexe: 'Fille',
    adresse: 'Rue des Lilas, Alger',
    photoPath: 'https://images.unsplash.com/photo-1607746882042-944635dfe10e',
    nomPrenomPere: 'Ahmed Boukhalfa',
    telPere: '0661122334',
    professionPere: 'Ingénieur',
    adressePere: 'Rue des Lilas, Alger',
    nomPrenomMere: 'Nadia Sahraoui',
    telMere: '0555987654',
    professionMere: 'Médecin',
    statutFamilial: 'Mariés',
   
    allergies: 'Arachides',
    commentairesMedicaux: 'Doit porter un bracelet anti-allergie.',
    dossierMedicalPath: 'assets/dossiers/yasmine_medical.pdf',
    historiquePresence: {
      DateTime(2025, 8, 1): "Présent",
      DateTime(2025, 8, 2): "Absent",
      DateTime(2025, 8, 3): "Présent",
      DateTime(2025, 8, 4): "Présent",
    },
   paiements: [
      Paiement(
        date: DateTime(2025, 7, 5),
        mois: 'Juillet 2025',
        montantPaye: 5000,
                montantdu: 5000,

        reste: 0,
        statut: StatutPaiements.paye,
      ),
      Paiement(
        date: DateTime(2025, 6, 5),
        mois: 'Juin 2025',
        montantPaye: 2000,
                montantdu: 5000,

        reste: 3000,
        statut: StatutPaiements.partiel,
      ),
      Paiement(
        date: DateTime(2025, 5, 5),
        mois: 'Mai 2025',
        montantPaye: 0,
                montantdu: 5000,

        reste: 5000,
        statut: StatutPaiements.impaye,
      ),
    ],
  ),
  
];


/// enfant vide pour la creation d un objet 
final emptyEnfant = Enfant(
  id: '',
  nom: '',
  prenom: '',
  classe: '',
  telephone: '',
  estActif: true,
  dateNaissance: '',
  sexe: '',
  adresse: '',
  nomPrenomPere: '',
  telPere: '',
  professionPere: '',
  adressePere: '',
  nomPrenomMere: '',
  telMere: '',
  professionMere: '',
  statutFamilial: '',

  allergies: '',
  commentairesMedicaux: '',
);


// ---------------- Dummy employés ----------------

List<Employe> dummyEmployes = [
  Employe(
    id: 'e1',
    nom: 'Benali',
    prenom: 'Ahmed',
    dateNaissance: DateTime(1985, 4, 12),
    dateEmbauche: DateTime(2010, 5, 1),
    poste: 'Comptable',
    salaire: 50000,
    telephone: '0555 123 456',
    adresse: 'Alger, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe1.jpg',
    paiements: [
      PaiementEmploye(
        datePaiement: DateTime(2025, 8, 1),
        mois: 'Août 2025',
        salaireBase: 50000,
        prime: 5000,
        montantPaye: 55000,
        statut: StatutPaiement.paye,
      ),
    ],
  ),
  Employe(
    id: 'e2',
    nom: 'Khelifi',
    prenom: 'Sara',
    dateNaissance: DateTime(1990, 9, 22),
    dateEmbauche: DateTime(2015, 3, 10),
    poste: 'Secrétaire',
    salaire: 35000,
    telephone: '0552 987 654',
    adresse: 'Oran, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe2.jpg',
    paiements: [
      PaiementEmploye(
        datePaiement: DateTime(2025, 8, 2),
        mois: 'Août 2025',
        salaireBase: 35000,
        prime: 2000,
        montantPaye: 37000,
        statut: StatutPaiement.paye,
      ),
    ],
  ),
  Employe(
    id: 'e3',
    nom: 'Meziani',
    prenom: 'Yacine',
    dateNaissance: DateTime(1988, 2, 5),
    dateEmbauche: DateTime(2018, 7, 15),
    poste: 'Technicien',
    salaire: 40000,
    telephone: '0553 111 222',
    adresse: 'Constantine, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe3.jpg',
    paiements: [
      PaiementEmploye(
        datePaiement: DateTime(2025, 8, 3),
        mois: 'Août 2025',
        salaireBase: 40000,
        prime: 3000,
        montantPaye: 43000,
        statut: StatutPaiement.paye,
      ),
    ],
  ),
  Employe(
    id: 'e4',
    nom: 'Brahimi',
    prenom: 'Karima',
    dateNaissance: DateTime(1992, 6, 30),
    dateEmbauche: DateTime(2020, 1, 20),
    poste: 'Assistante RH',
    salaire: 32000,
    telephone: '0556 444 555',
    adresse: 'Tizi Ouzou, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe4.jpg',
    paiements: [
      PaiementEmploye(
        datePaiement: DateTime(2025, 8, 4),
        mois: 'Août 2025',
        salaireBase: 32000,
        prime: 1500,
        montantPaye: 33500,
        statut: StatutPaiement.paye,
      ),
    ],
  ),
  Employe(
    id: 'e5',
    nom: 'Saidi',
    prenom: 'Mohamed',
    dateNaissance: DateTime(1980, 12, 10),
    dateEmbauche: DateTime(2005, 11, 5),
    poste: 'Chef d\'atelier',
    salaire: 60000,
    telephone: '0557 666 777',
    adresse: 'Annaba, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe5.jpg',
    paiements: [
      PaiementEmploye(
        datePaiement: DateTime(2025, 8, 5),
        mois: 'Août 2025',
        salaireBase: 60000,
        prime: 7000,
        montantPaye: 67000,
        statut: StatutPaiement.paye,
      ),
    ],
  ),
  Employe(
    id: 'e6',
    nom: 'Cherif',
    prenom: 'Lamia',
    dateNaissance: DateTime(1995, 8, 15),
    dateEmbauche: DateTime(2021, 4, 1),
    poste: 'Designer',
    salaire: 30000,
    telephone: '0558 888 999',
    adresse: 'Béjaïa, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe6.jpg',
    paiements: [],
  ),
  Employe(
    id: 'e7',
    nom: 'Bensaid',
    prenom: 'Rachid',
    dateNaissance: DateTime(1987, 5, 19),
    dateEmbauche: DateTime(2016, 2, 17),
    poste: 'Magasinier',
    salaire: 28000,
    telephone: '0559 101 202',
    adresse: 'Blida, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe7.jpg',
    paiements: [],
  ),
  Employe(
    id: 'e8',
    nom: 'Haddad',
    prenom: 'Sonia',
    dateNaissance: DateTime(1993, 3, 8),
    dateEmbauche: DateTime(2019, 9, 12),
    poste: 'Responsable Marketing',
    salaire: 55000,
    telephone: '0560 303 404',
    adresse: 'Alger, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe8.jpg',
    paiements: [],
  ),
  Employe(
    id: 'e9',
    nom: 'Ouali',
    prenom: 'Samir',
    dateNaissance: DateTime(1982, 1, 25),
    dateEmbauche: DateTime(2008, 6, 30),
    poste: 'Ingénieur',
    salaire: 70000,
    telephone: '0561 505 606',
    adresse: 'Oran, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe9.jpg',
    paiements: [],
  ),
  Employe(
    id: 'e10',
    nom: 'Boumediene',
    prenom: 'Nadia',
    dateNaissance: DateTime(1998, 7, 14),
    dateEmbauche: DateTime(2023, 2, 14),
    poste: 'Stagiaire',
    salaire: 20000,
    telephone: '0562 707 808',
    adresse: 'Setif, Algérie',
    estActif: true,
    photoUrl: 'assets/images/employe10.jpg',
    paiements: [],
  ),
];

















List<Activity> activities = [
  // Monday - Classe A
  Activity(
    id: '1',
    className: 'Classe A',
    title: 'Peinture',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 10, minute: 30),
    notes: 'Peinture à l\'eau',
  ),
  Activity(
    id: '2',
    className: 'Classe A',
    title: 'Lecture',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 11, minute: 0),
    end: TimeOfDay(hour: 12, minute: 0),
    notes: 'Lecture en groupe',
  ),
  Activity(
    id: '3',
    className: 'Classe A',
    title: 'Jeux',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 14, minute: 0),
    end: TimeOfDay(hour: 15, minute: 0),
    notes: 'Jeux éducatifs',
  ),

  // Monday - Classe B
  Activity(
    id: '4',
    className: 'Classe B',
    title: 'Musique',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 8, minute: 30),
    end: TimeOfDay(hour: 9, minute: 30),
    notes: 'Initiation aux instruments',
  ),
  Activity(
    id: '5',
    className: 'Classe B',
    title: 'Sport',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 10, minute: 0),
    end: TimeOfDay(hour: 11, minute: 30),
    notes: 'Exercices physiques',
  ),
  Activity(
    id: '6',
    className: 'Classe B',
    title: 'Art',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 13, minute: 30),
    end: TimeOfDay(hour: 14, minute: 30),
    notes: 'Collage et découpage',
  ),

  // Monday - Classe C
  Activity(
    id: '7',
    className: 'Classe C',
    title: 'Jeux',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 10, minute: 0),
    notes: 'Jeux de société',
  ),
  Activity(
    id: '8',
    className: 'Classe C',
    title: 'Lecture',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 11, minute: 0),
    end: TimeOfDay(hour: 12, minute: 0),
    notes: 'Histoires courtes',
  ),
  Activity(
    id: '9',
    className: 'Classe C',
    title: 'Musique',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    start: TimeOfDay(hour: 15, minute: 0),
    end: TimeOfDay(hour: 16, minute: 0),
    notes: 'Chansons pour enfants',
  ),

  // Tuesday - Classe A
  Activity(
    id: '10',
    className: 'Classe A',
    title: 'Sport',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 8, minute: 30),
    end: TimeOfDay(hour: 9, minute: 30),
    notes: 'Exercices matinaux',
  ),
  Activity(
    id: '11',
    className: 'Classe A',
    title: 'Art',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 10, minute: 30),
    end: TimeOfDay(hour: 11, minute: 30),
    notes: 'Dessin libre',
  ),
  Activity(
    id: '12',
    className: 'Classe A',
    title: 'Musique',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 14, minute: 0),
    end: TimeOfDay(hour: 15, minute: 0),
    notes: 'Rythmes et percussions',
  ),

  // Tuesday - Classe B
  Activity(
    id: '13',
    className: 'Classe B',
    title: 'Lecture',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 10, minute: 0),
    notes: 'Lecture silencieuse',
  ),
  Activity(
    id: '14',
    className: 'Classe B',
    title: 'Jeux',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 11, minute: 0),
    end: TimeOfDay(hour: 12, minute: 0),
    notes: 'Jeux de construction',
  ),
  Activity(
    id: '15',
    className: 'Classe B',
    title: 'Peinture',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 13, minute: 30),
    end: TimeOfDay(hour: 14, minute: 30),
    notes: 'Peinture au doigt',
  ),

  // Tuesday - Classe C
  Activity(
    id: '16',
    className: 'Classe C',
    title: 'Art',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 8, minute: 45),
    end: TimeOfDay(hour: 9, minute: 45),
    notes: 'Modelage en pâte à modeler',
  ),
  Activity(
    id: '17',
    className: 'Classe C',
    title: 'Sport',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 10, minute: 30),
    end: TimeOfDay(hour: 11, minute: 30),
    notes: 'Parcours moteur',
  ),
  Activity(
    id: '18',
    className: 'Classe C',
    title: 'Lecture',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 2)),
    start: TimeOfDay(hour: 15, minute: 0),
    end: TimeOfDay(hour: 16, minute: 0),
    notes: 'Lecture interactive',
  ),

  // Wednesday - Classe A
  Activity(
    id: '19',
    className: 'Classe A',
    title: 'Musique',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 3)),
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 10, minute: 0),
    notes: 'Découverte des instruments',
  ),
  Activity(
    id: '20',
    className: 'Classe A',
    title: 'Jeux',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 3)),
    start: TimeOfDay(hour: 11, minute: 0),
    end: TimeOfDay(hour: 12, minute: 0),
    notes: 'Jeux de mémoire',
  ),
  Activity(
    id: '21',
    className: 'Classe A',
    title: 'Art',
    date: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 3)),
    start: TimeOfDay(hour: 14, minute: 0),
    end: TimeOfDay(hour: 15, minute: 0),
    notes: 'Création avec des matériaux recyclés',
  ),

  // Continue this pattern for Wednesday (Classe B, C), Thursday, Friday
  // Each day should have 3 activities per class
  // Total of 3 classes × 3 activities × 5 days = 45 activities
  // (I've shown the pattern for Monday-Wednesday, you can continue similarly)
];



List<Depense> dummyDepenses = [
  Depense(
    id: 'd1',
    categorie: 'Salaire',
    description: 'Salaire Employé Ahmed',
    montant: 30000,
    date: DateTime(2025, 7, 10),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd2',
    categorie: 'Salaire',
    description: 'Salaire Employée Samira',
    montant: 28000,
    date: DateTime(2025, 7, 10),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd3',
    categorie: 'Achat Matériel',
    description: 'Ordinateur portable HP',
    montant: 85000,
    date: DateTime(2025, 6, 15),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd4',
    categorie: 'Maintenance',
    description: 'Réparation climatisation',
    montant: 15000,
    date: DateTime(2025, 6, 20),
    attestation: 'Impayé',
  ),
  Depense(
    id: 'd5',
    categorie: 'Fournitures',
    description: 'Papeterie et stylos',
    montant: 3000,
    date: DateTime(2025, 6, 5),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd6',
    categorie: 'Transport',
    description: 'Carburant véhicule société',
    montant: 12000,
    date: DateTime(2025, 7, 2),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd7',
    categorie: 'Événement',
    description: 'Organisation fête annuelle',
    montant: 25000,
    date: DateTime(2025, 5, 30),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd8',
    categorie: 'Achat Matériel',
    description: 'Projecteur Epson',
    montant: 60000,
    date: DateTime(2025, 7, 5),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd9',
    categorie: 'Maintenance',
    description: 'Réparation imprimante',
    montant: 5000,
    date: DateTime(2025, 6, 25),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd10',
    categorie: 'Fournitures',
    description: 'Achat papier A4',
    montant: 2000,
    date: DateTime(2025, 7, 1),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd11',
    categorie: 'Salaire',
    description: 'Salaire Employé Karim',
    montant: 32000,
    date: DateTime(2025, 7, 10),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd12',
    categorie: 'Transport',
    description: 'Révision véhicule société',
    montant: 8000,
    date: DateTime(2025, 6, 18),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd13',
    categorie: 'Achat Matériel',
    description: 'Téléphone portable Samsung',
    montant: 40000,
    date: DateTime(2025, 6, 28),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd14',
    categorie: 'Maintenance',
    description: 'Nettoyage et entretien locaux',
    montant: 7000,
    date: DateTime(2025, 6, 12),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd15',
    categorie: 'Fournitures',
    description: 'Encres imprimante',
    montant: 4500,
    date: DateTime(2025, 7, 3),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd16',
    categorie: 'Événement',
    description: 'Location salle réunion',
    montant: 10000,
    date: DateTime(2025, 7, 8),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd17',
    categorie: 'Salaire',
    description: 'Salaire Employée Lina',
    montant: 29000,
    date: DateTime(2025, 7, 10),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd18',
    categorie: 'Achat Matériel',
    description: 'Table de bureau en bois',
    montant: 15000,
    date: DateTime(2025, 6, 22),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd19',
    categorie: 'Maintenance',
    description: 'Peinture mur bureau',
    montant: 12000,
    date: DateTime(2025, 7, 6),
    attestation: 'Payé',
  ),
  Depense(
    id: 'd20',
    categorie: 'Transport',
    description: 'Taxi pour déplacement client',
    montant: 2500,
    date: DateTime(2025, 6, 14),
    attestation: 'Payé',
  ),
];





















// dummydata/dummy_users.dart


final dummyUsers = [
  AppUser(
    id: "1",
    username: "admin",
    password: "1234",
    role: UserRole.admin,
  ),
  AppUser(
    id: "2",
    username: "user1",
    password: "abcd",
    role: UserRole.standard,
  ),
];
