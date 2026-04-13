class Utilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;
  final String devise;
  final String? photoProfil;
  final String statut;
  final DateTime dateInscription;
  final DateTime updatedAt;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    this.devise = 'FCFA',
    this.photoProfil,
    this.statut = 'actif',
    required this.dateInscription,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'mot_de_passe': motDePasse,
    'devise': devise,
    'photo_profil': photoProfil,
    'statut': statut,
    'date_inscription': dateInscription.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Utilisateur.fromMap(Map<String, dynamic> map) => Utilisateur(
    id: map['id'],
    nom: map['nom'],
    prenom: map['prenom'],
    email: map['email'],
    motDePasse: map['mot_de_passe'],
    devise: map['devise'] ?? 'FCFA',
    photoProfil: map['photo_profil'],
    statut: map['statut'] ?? 'actif',
    dateInscription: DateTime.parse(map['date_inscription']),
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'])
        : DateTime.fromMillisecondsSinceEpoch(0),
  );

  Utilisateur copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? devise,
    String? photoProfil,
    String? statut,
    DateTime? updatedAt,
  }) =>
    Utilisateur(
      id: id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      motDePasse: motDePasse,
      devise: devise ?? this.devise,
      photoProfil: photoProfil ?? this.photoProfil,
      statut: statut ?? this.statut,
      dateInscription: dateInscription,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}

class Categorie {
  final String id;
  final String nom;
  final String icone;
  final String couleur;
  final String type; // depense ou revenu
  final bool estSysteme;
  final bool estArchivee;
  final String? utilisateurId;
  final DateTime updatedAt;

  Categorie({
    required this.id,
    required this.nom,
    required this.icone,
    required this.couleur,
    required this.type,
    this.estSysteme = false,
    this.estArchivee = false,
    this.utilisateurId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'icone': icone,
    'couleur': couleur,
    'type': type,
    'est_systeme': estSysteme ? 1 : 0,
    'est_archivee': estArchivee ? 1 : 0,
    'utilisateur_id': utilisateurId,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Categorie.fromMap(Map<String, dynamic> map) => Categorie(
    id: map['id'],
    nom: map['nom'],
    icone: map['icone'],
    couleur: map['couleur'],
    type: map['type'],
    estSysteme: map['est_systeme'] == 1,
    estArchivee: map['est_archivee'] == 1,
    utilisateurId: map['utilisateur_id'],
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'])
        : DateTime.fromMillisecondsSinceEpoch(0),
  );

  Categorie copyWith({
    String? nom,
    String? icone,
    String? couleur,
    bool? estArchivee,
    DateTime? updatedAt,
  }) =>
      Categorie(
        id: id,
        nom: nom ?? this.nom,
        icone: icone ?? this.icone,
        couleur: couleur ?? this.couleur,
        type: type,
        estSysteme: estSysteme,
        estArchivee: estArchivee ?? this.estArchivee,
        utilisateurId: utilisateurId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class Compte {
  final String id;
  final String nom;
  double solde;
  final String icone;
  final String couleur;
  final String? operateur; // TMoney, Flooz, Yas
  final String utilisateurId;
  final DateTime updatedAt;

  Compte({
    required this.id,
    required this.nom,
    required this.solde,
    required this.icone,
    required this.couleur,
    this.operateur,
    required this.utilisateurId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'solde': solde,
        'icone': icone,
        'couleur': couleur,
        'operateur': operateur,
        'utilisateur_id': utilisateurId,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Compte.fromMap(Map<String, dynamic> map) => Compte(
        id: map['id'],
        nom: map['nom'],
        solde: double.tryParse(map['solde'].toString()) ?? 0.0,
        icone: map['icone'],
        couleur: map['couleur'],
        operateur: map['operateur'],
        utilisateurId: map['utilisateur_id'],
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : DateTime.now(),
      );
}

class Transaction {
  final String id;
  final double montant;
  final String type; // depense ou revenu
  final DateTime dateTransaction;
  final String? description;
  final String modePaiement;
  final String? justificatif;
  final String categorieId;
  final String? compteId;
  final String utilisateurId;
  final DateTime dateCreation;
  final DateTime updatedAt;
  Categorie? categorie;

  Transaction({
    required this.id,
    required this.montant,
    required this.type,
    required this.dateTransaction,
    this.description,
    this.modePaiement = 'especes',
    this.justificatif,
    required this.categorieId,
    this.compteId,
    required this.utilisateurId,
    required this.dateCreation,
    DateTime? updatedAt,
    this.categorie,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'montant': montant,
    'type': type,
    'date_transaction': dateTransaction.toIso8601String(),
    'description': description,
    'mode_paiement': modePaiement,
    'justificatif': justificatif,
    'categorie_id': categorieId,
    'compte_id': compteId,
    'utilisateur_id': utilisateurId,
    'date_creation': dateCreation.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    montant: map['montant'].toDouble(),
    type: map['type'],
    dateTransaction: DateTime.parse(map['date_transaction']),
    description: map['description'],
    modePaiement: map['mode_paiement'] ?? 'especes',
    justificatif: map['justificatif'],
    categorieId: map['categorie_id'],
    compteId: map['compte_id'],
    utilisateurId: map['utilisateur_id'],
    dateCreation: DateTime.parse(map['date_creation']),
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'])
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class Budget {
  final String id;
  double montantAlloue;
  double montantDepense;
  double montantReporte;
  final String periode;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? categorieId;
  final String utilisateurId;
  bool statutAlerte;
  bool alerte80Envoyee;
  bool alerte100Envoyee;
  Categorie? categorie;
  DateTime updatedAt;

  Budget({
    required this.id,
    required this.montantAlloue,
    this.montantDepense = 0,
    this.montantReporte = 0,
    this.periode = 'mensuel',
    required this.dateDebut,
    required this.dateFin,
    this.categorieId,
    required this.utilisateurId,
    this.statutAlerte = false,
    this.alerte80Envoyee = false,
    this.alerte100Envoyee = false,
    this.categorie,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  double get pourcentage => montantAlloue > 0 ? (montantDepense / montantAlloue).clamp(0, 1) : 0;
  double get restant => montantAlloue - montantDepense;
  bool get estDepasse => montantDepense > montantAlloue;

  Map<String, dynamic> toMap() => {
    'id': id,
    'montant_alloue': montantAlloue,
    'montant_depense': montantDepense,
    'montant_reporte': montantReporte,
    'periode': periode,
    'date_debut': dateDebut.toIso8601String(),
    'date_fin': dateFin.toIso8601String(),
    'categorie_id': categorieId,
    'utilisateur_id': utilisateurId,
    'statut_alerte': statutAlerte ? 1 : 0,
    'alerte_80_envoyee': alerte80Envoyee ? 1 : 0,
    'alerte_100_envoyee': alerte100Envoyee ? 1 : 0,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'],
    montantAlloue: map['montant_alloue'].toDouble(),
    montantDepense: map['montant_depense']?.toDouble() ?? 0,
    montantReporte: map['montant_reporte']?.toDouble() ?? 0,
    periode: map['periode'] ?? 'mensuel',
    dateDebut: DateTime.parse(map['date_debut']),
    dateFin: DateTime.parse(map['date_fin']),
    categorieId: map['categorie_id'],
    utilisateurId: map['utilisateur_id'],
    statutAlerte: map['statut_alerte'] == 1,
    alerte80Envoyee: map['alerte_80_envoyee'] == 1,
    alerte100Envoyee: map['alerte_100_envoyee'] == 1,
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'])
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class Alerte {
  final String id;
  final String typeAlerte;
  final String message;
  final DateTime dateEnvoi;
  final bool estLue;
  final String utilisateurId;
  final String? budgetId;
  final DateTime updatedAt;

  Alerte({
    required this.id,
    required this.typeAlerte,
    required this.message,
    required this.dateEnvoi,
    required this.estLue,
    required this.utilisateurId,
    this.budgetId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'type_alerte': typeAlerte,
        'message': message,
        'date_envoi': dateEnvoi.toIso8601String(),
        'est_lue': estLue ? 1 : 0,
        'utilisateur_id': utilisateurId,
        'budget_id': budgetId,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Alerte.fromMap(Map<String, dynamic> map) => Alerte(
        id: map['id'],
        typeAlerte: map['type_alerte'],
        message: map['message'],
        dateEnvoi: DateTime.parse(map['date_envoi']),
        estLue: map['est_lue'] == 1,
        utilisateurId: map['utilisateur_id'],
        budgetId: map['budget_id'],
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class TransactionRecurrente {
  final String id;
  final double montant;
  final String type; // depense ou revenu
  final DateTime dateDebut;
  final DateTime prochaineDate;
  final String periodicite; // hebdomadaire, mensuel, annuel
  final String? description;
  final String modePaiement;
  final String categorieId;
  final String? compteId;
  final String utilisateurId;
  final bool actif;
  Categorie? categorie;
  final DateTime updatedAt;

  TransactionRecurrente({
    required this.id,
    required this.montant,
    required this.type,
    required this.dateDebut,
    required this.prochaineDate,
    required this.periodicite,
    this.description,
    this.modePaiement = 'especes',
    required this.categorieId,
    this.compteId,
    required this.utilisateurId,
    this.actif = true,
    this.categorie,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'montant': montant,
        'type': type,
        'date_debut': dateDebut.toIso8601String(),
        'prochaine_date': prochaineDate.toIso8601String(),
        'periodicite': periodicite,
        'description': description,
        'mode_paiement': modePaiement,
        'categorie_id': categorieId,
        'compte_id': compteId,
        'utilisateur_id': utilisateurId,
        'actif': actif ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TransactionRecurrente.fromMap(Map<String, dynamic> map) =>
      TransactionRecurrente(
        id: map['id'],
        montant: map['montant'].toDouble(),
        type: map['type'],
        dateDebut: DateTime.parse(map['date_debut']),
        prochaineDate: DateTime.parse(map['prochaine_date']),
        periodicite: map['periodicite'],
        description: map['description'],
        modePaiement: map['mode_paiement'] ?? 'especes',
        categorieId: map['categorie_id'],
        compteId: map['compte_id'],
        utilisateurId: map['utilisateur_id'],
        actif: map['actif'] == 1,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class Objectif {
  final String id;
  final String nom;
  final double montantCible;
  double montantActuel;
  final DateTime dateEcheance;
  String statut; // en_cours, atteint, abandonne
  final String utilisateurId;
  final DateTime updatedAt;

  Objectif({
    required this.id,
    required this.nom,
    required this.montantCible,
    this.montantActuel = 0,
    required this.dateEcheance,
    this.statut = 'en_cours',
    required this.utilisateurId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  double get pourcentage => montantCible > 0 ? (montantActuel / montantCible).clamp(0, 1) : 0;
  double get restant => montantCible - montantActuel;

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'montant_cible': montantCible,
    'montant_actuel': montantActuel,
    'date_echeance': dateEcheance.toIso8601String(),
    'statut': statut,
    'utilisateur_id': utilisateurId,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Objectif.fromMap(Map<String, dynamic> map) => Objectif(
    id: map['id'],
    nom: map['nom'],
    montantCible: map['montant_cible'].toDouble(),
    montantActuel: map['montant_actuel']?.toDouble() ?? 0,
    dateEcheance: DateTime.parse(map['date_echeance']),
    statut: map['statut'] ?? 'en_cours',
    utilisateurId: map['utilisateur_id'],
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'])
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}
