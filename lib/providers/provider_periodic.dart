import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

PeriodicTableModel periodicTableModel = PeriodicTableModel();

MyProvider providerPeriodicTable = MyProvider(
    name: "PeriodicTable",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Periodic Table',
      keywords: 'periodic table element chemistry atomic science',
      action: () => periodicTableModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  periodicTableModel.init();
  Global.infoModel.addInfoWidget(
      "PeriodicTable",
      ChangeNotifierProvider.value(
          value: periodicTableModel,
          builder: (context, child) => PeriodicTableCard()),
      title: "Periodic Table");
}

Future<void> _update() async {
  periodicTableModel.refresh();
}

enum ElementCategory {
  alkaliMetal,
  alkalineEarthMetal,
  transitionMetal,
  postTransitionMetal,
  metalloid,
  nonmetal,
  halogen,
  nobleGas,
  lanthanide,
  actinide,
  unknown,
}

class ChemicalElement {
  final int atomicNumber;
  final String symbol;
  final String name;
  final double atomicMass;
  final ElementCategory category;
  final int? group;
  final int? period;
  final String? electronConfiguration;
  final String? discoveryYear;
  
  const ChemicalElement({
    required this.atomicNumber,
    required this.symbol,
    required this.name,
    required this.atomicMass,
    required this.category,
    this.group,
    this.period,
    this.electronConfiguration,
    this.discoveryYear,
  });
}

const List<ChemicalElement> chemicalElements = [
  ChemicalElement(atomicNumber: 1, symbol: 'H', name: 'Hydrogen', atomicMass: 1.008, category: ElementCategory.nonmetal, group: 1, period: 1, electronConfiguration: '1s¹'),
  ChemicalElement(atomicNumber: 2, symbol: 'He', name: 'Helium', atomicMass: 4.0026, category: ElementCategory.nobleGas, group: 18, period: 1, electronConfiguration: '1s²'),
  ChemicalElement(atomicNumber: 3, symbol: 'Li', name: 'Lithium', atomicMass: 6.94, category: ElementCategory.alkaliMetal, group: 1, period: 2, electronConfiguration: '[He] 2s¹'),
  ChemicalElement(atomicNumber: 4, symbol: 'Be', name: 'Beryllium', atomicMass: 9.0122, category: ElementCategory.alkalineEarthMetal, group: 2, period: 2, electronConfiguration: '[He] 2s²'),
  ChemicalElement(atomicNumber: 5, symbol: 'B', name: 'Boron', atomicMass: 10.81, category: ElementCategory.metalloid, group: 13, period: 2, electronConfiguration: '[He] 2s² 2p¹'),
  ChemicalElement(atomicNumber: 6, symbol: 'C', name: 'Carbon', atomicMass: 12.011, category: ElementCategory.nonmetal, group: 14, period: 2, electronConfiguration: '[He] 2s² 2p²'),
  ChemicalElement(atomicNumber: 7, symbol: 'N', name: 'Nitrogen', atomicMass: 14.007, category: ElementCategory.nonmetal, group: 15, period: 2, electronConfiguration: '[He] 2s² 2p³'),
  ChemicalElement(atomicNumber: 8, symbol: 'O', name: 'Oxygen', atomicMass: 15.999, category: ElementCategory.nonmetal, group: 16, period: 2, electronConfiguration: '[He] 2s² 2p⁴'),
  ChemicalElement(atomicNumber: 9, symbol: 'F', name: 'Fluorine', atomicMass: 18.998, category: ElementCategory.halogen, group: 17, period: 2, electronConfiguration: '[He] 2s² 2p⁵'),
  ChemicalElement(atomicNumber: 10, symbol: 'Ne', name: 'Neon', atomicMass: 20.180, category: ElementCategory.nobleGas, group: 18, period: 2, electronConfiguration: '[He] 2s² 2p⁶'),
  ChemicalElement(atomicNumber: 11, symbol: 'Na', name: 'Sodium', atomicMass: 22.990, category: ElementCategory.alkaliMetal, group: 1, period: 3, electronConfiguration: '[Ne] 3s¹'),
  ChemicalElement(atomicNumber: 12, symbol: 'Mg', name: 'Magnesium', atomicMass: 24.305, category: ElementCategory.alkalineEarthMetal, group: 2, period: 3, electronConfiguration: '[Ne] 3s²'),
  ChemicalElement(atomicNumber: 13, symbol: 'Al', name: 'Aluminum', atomicMass: 26.982, category: ElementCategory.postTransitionMetal, group: 13, period: 3, electronConfiguration: '[Ne] 3s² 3p¹'),
  ChemicalElement(atomicNumber: 14, symbol: 'Si', name: 'Silicon', atomicMass: 28.085, category: ElementCategory.metalloid, group: 14, period: 3, electronConfiguration: '[Ne] 3s² 3p²'),
  ChemicalElement(atomicNumber: 15, symbol: 'P', name: 'Phosphorus', atomicMass: 30.974, category: ElementCategory.nonmetal, group: 15, period: 3, electronConfiguration: '[Ne] 3s² 3p³'),
  ChemicalElement(atomicNumber: 16, symbol: 'S', name: 'Sulfur', atomicMass: 32.06, category: ElementCategory.nonmetal, group: 16, period: 3, electronConfiguration: '[Ne] 3s² 3p⁴'),
  ChemicalElement(atomicNumber: 17, symbol: 'Cl', name: 'Chlorine', atomicMass: 35.45, category: ElementCategory.halogen, group: 17, period: 3, electronConfiguration: '[Ne] 3s² 3p⁵'),
  ChemicalElement(atomicNumber: 18, symbol: 'Ar', name: 'Argon', atomicMass: 39.948, category: ElementCategory.nobleGas, group: 18, period: 3, electronConfiguration: '[Ne] 3s² 3p⁶'),
  ChemicalElement(atomicNumber: 19, symbol: 'K', name: 'Potassium', atomicMass: 39.098, category: ElementCategory.alkaliMetal, group: 1, period: 4, electronConfiguration: '[Ar] 4s¹'),
  ChemicalElement(atomicNumber: 20, symbol: 'Ca', name: 'Calcium', atomicMass: 40.078, category: ElementCategory.alkalineEarthMetal, group: 2, period: 4, electronConfiguration: '[Ar] 4s²'),
  ChemicalElement(atomicNumber: 21, symbol: 'Sc', name: 'Scandium', atomicMass: 44.956, category: ElementCategory.transitionMetal, group: 3, period: 4, electronConfiguration: '[Ar] 3d¹ 4s²'),
  ChemicalElement(atomicNumber: 22, symbol: 'Ti', name: 'Titanium', atomicMass: 47.867, category: ElementCategory.transitionMetal, group: 4, period: 4, electronConfiguration: '[Ar] 3d² 4s²'),
  ChemicalElement(atomicNumber: 23, symbol: 'V', name: 'Vanadium', atomicMass: 50.942, category: ElementCategory.transitionMetal, group: 5, period: 4, electronConfiguration: '[Ar] 3d³ 4s²'),
  ChemicalElement(atomicNumber: 24, symbol: 'Cr', name: 'Chromium', atomicMass: 51.996, category: ElementCategory.transitionMetal, group: 6, period: 4, electronConfiguration: '[Ar] 3d⁵ 4s¹'),
  ChemicalElement(atomicNumber: 25, symbol: 'Mn', name: 'Manganese', atomicMass: 54.938, category: ElementCategory.transitionMetal, group: 7, period: 4, electronConfiguration: '[Ar] 3d⁵ 4s²'),
  ChemicalElement(atomicNumber: 26, symbol: 'Fe', name: 'Iron', atomicMass: 55.845, category: ElementCategory.transitionMetal, group: 8, period: 4, electronConfiguration: '[Ar] 3d⁶ 4s²'),
  ChemicalElement(atomicNumber: 27, symbol: 'Co', name: 'Cobalt', atomicMass: 58.933, category: ElementCategory.transitionMetal, group: 9, period: 4, electronConfiguration: '[Ar] 3d⁷ 4s²'),
  ChemicalElement(atomicNumber: 28, symbol: 'Ni', name: 'Nickel', atomicMass: 58.693, category: ElementCategory.transitionMetal, group: 10, period: 4, electronConfiguration: '[Ar] 3d⁸ 4s²'),
  ChemicalElement(atomicNumber: 29, symbol: 'Cu', name: 'Copper', atomicMass: 63.546, category: ElementCategory.transitionMetal, group: 11, period: 4, electronConfiguration: '[Ar] 3d¹⁰ 4s¹'),
  ChemicalElement(atomicNumber: 30, symbol: 'Zn', name: 'Zinc', atomicMass: 65.38, category: ElementCategory.transitionMetal, group: 12, period: 4, electronConfiguration: '[Ar] 3d¹⁰ 4s²'),
  ChemicalElement(atomicNumber: 31, symbol: 'Ga', name: 'Gallium', atomicMass: 69.723, category: ElementCategory.postTransitionMetal, group: 13, period: 4, electronConfiguration: '[Ar] 3d¹⁰ 4s² 4p¹'),
  ChemicalElement(atomicNumber: 32, symbol: 'Ge', name: 'Germanium', atomicMass: 72.630, category: ElementCategory.metalloid, group: 14, period: 4, electronConfiguration: '[Ar] 3d¹⁰ 4s² 4p²'),
  ChemicalElement(atomicNumber: 33, symbol: 'As', name: 'Arsenic', atomicMass: 74.922, category: ElementCategory.metalloid, group: 15, period: 4, electronConfiguration: '[Ar] 3d¹⁰ 4s² 4p³'),
  ChemicalElement(atomicNumber: 34, symbol: 'Se', name: 'Selenium', atomicMass: 78.971, category: ElementCategory.nonmetal, group: 16, period: 4, electronConfiguration: '[Ar] 3d¹⁰ 4s² 4p⁴'),
  ChemicalElement(atomicNumber: 35, symbol: 'Br', name: 'Bromine', atomicMass: 79.904, category: ElementCategory.halogen, group: 17, period: 4, electronConfiguration: '[Ar] 3d¹⁰ 4s² 4p⁵'),
  ChemicalElement(atomicNumber: 36, symbol: 'Kr', name: 'Krypton', atomicMass: 83.798, category: ElementCategory.nobleGas, group: 18, period: 4, electronConfiguration: '[Ar] 3d¹⁰ 4s² 4p⁶'),
  ChemicalElement(atomicNumber: 37, symbol: 'Rb', name: 'Rubidium', atomicMass: 85.468, category: ElementCategory.alkaliMetal, group: 1, period: 5, electronConfiguration: '[Kr] 5s¹'),
  ChemicalElement(atomicNumber: 38, symbol: 'Sr', name: 'Strontium', atomicMass: 87.62, category: ElementCategory.alkalineEarthMetal, group: 2, period: 5, electronConfiguration: '[Kr] 5s²'),
  ChemicalElement(atomicNumber: 39, symbol: 'Y', name: 'Yttrium', atomicMass: 88.906, category: ElementCategory.transitionMetal, group: 3, period: 5, electronConfiguration: '[Kr] 4d¹ 5s²'),
  ChemicalElement(atomicNumber: 40, symbol: 'Zr', name: 'Zirconium', atomicMass: 91.224, category: ElementCategory.transitionMetal, group: 4, period: 5, electronConfiguration: '[Kr] 4d² 5s²'),
  ChemicalElement(atomicNumber: 41, symbol: 'Nb', name: 'Niobium', atomicMass: 92.906, category: ElementCategory.transitionMetal, group: 5, period: 5, electronConfiguration: '[Kr] 4d⁴ 5s¹'),
  ChemicalElement(atomicNumber: 42, symbol: 'Mo', name: 'Molybdenum', atomicMass: 95.95, category: ElementCategory.transitionMetal, group: 6, period: 5, electronConfiguration: '[Kr] 4d⁵ 5s¹'),
  ChemicalElement(atomicNumber: 43, symbol: 'Tc', name: 'Technetium', atomicMass: 98, category: ElementCategory.transitionMetal, group: 7, period: 5, electronConfiguration: '[Kr] 4d⁵ 5s²', discoveryYear: '1937'),
  ChemicalElement(atomicNumber: 44, symbol: 'Ru', name: 'Ruthenium', atomicMass: 101.07, category: ElementCategory.transitionMetal, group: 8, period: 5, electronConfiguration: '[Kr] 4d⁷ 5s¹'),
  ChemicalElement(atomicNumber: 45, symbol: 'Rh', name: 'Rhodium', atomicMass: 102.91, category: ElementCategory.transitionMetal, group: 9, period: 5, electronConfiguration: '[Kr] 4d⁸ 5s¹'),
  ChemicalElement(atomicNumber: 46, symbol: 'Pd', name: 'Palladium', atomicMass: 106.42, category: ElementCategory.transitionMetal, group: 10, period: 5, electronConfiguration: '[Kr] 4d¹⁰'),
  ChemicalElement(atomicNumber: 47, symbol: 'Ag', name: 'Silver', atomicMass: 107.87, category: ElementCategory.transitionMetal, group: 11, period: 5, electronConfiguration: '[Kr] 4d¹⁰ 5s¹'),
  ChemicalElement(atomicNumber: 48, symbol: 'Cd', name: 'Cadmium', atomicMass: 112.41, category: ElementCategory.transitionMetal, group: 12, period: 5, electronConfiguration: '[Kr] 4d¹⁰ 5s²'),
  ChemicalElement(atomicNumber: 49, symbol: 'In', name: 'Indium', atomicMass: 114.82, category: ElementCategory.postTransitionMetal, group: 13, period: 5, electronConfiguration: '[Kr] 4d¹⁰ 5s² 5p¹'),
  ChemicalElement(atomicNumber: 50, symbol: 'Sn', name: 'Tin', atomicMass: 118.71, category: ElementCategory.postTransitionMetal, group: 14, period: 5, electronConfiguration: '[Kr] 4d¹⁰ 5s² 5p²'),
  ChemicalElement(atomicNumber: 51, symbol: 'Sb', name: 'Antimony', atomicMass: 121.76, category: ElementCategory.metalloid, group: 15, period: 5, electronConfiguration: '[Kr] 4d¹⁰ 5s² 5p³'),
  ChemicalElement(atomicNumber: 52, symbol: 'Te', name: 'Tellurium', atomicMass: 127.60, category: ElementCategory.metalloid, group: 16, period: 5, electronConfiguration: '[Kr] 4d¹⁰ 5s² 5p⁴'),
  ChemicalElement(atomicNumber: 53, symbol: 'I', name: 'Iodine', atomicMass: 126.90, category: ElementCategory.halogen, group: 17, period: 5, electronConfiguration: '[Kr] 4d¹⁰ 5s² 5p⁵'),
  ChemicalElement(atomicNumber: 54, symbol: 'Xe', name: 'Xenon', atomicMass: 131.29, category: ElementCategory.nobleGas, group: 18, period: 5, electronConfiguration: '[Kr] 4d¹⁰ 5s² 5p⁶'),
  ChemicalElement(atomicNumber: 55, symbol: 'Cs', name: 'Cesium', atomicMass: 132.91, category: ElementCategory.alkaliMetal, group: 1, period: 6, electronConfiguration: '[Xe] 6s¹'),
  ChemicalElement(atomicNumber: 56, symbol: 'Ba', name: 'Barium', atomicMass: 137.33, category: ElementCategory.alkalineEarthMetal, group: 2, period: 6, electronConfiguration: '[Xe] 6s²'),
  ChemicalElement(atomicNumber: 57, symbol: 'La', name: 'Lanthanum', atomicMass: 138.91, category: ElementCategory.lanthanide, group: 3, period: 6, electronConfiguration: '[Xe] 5d¹ 6s²'),
  ChemicalElement(atomicNumber: 58, symbol: 'Ce', name: 'Cerium', atomicMass: 140.12, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f¹ 5d¹ 6s²'),
  ChemicalElement(atomicNumber: 59, symbol: 'Pr', name: 'Praseodymium', atomicMass: 140.91, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f³ 6s²'),
  ChemicalElement(atomicNumber: 60, symbol: 'Nd', name: 'Neodymium', atomicMass: 144.24, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f⁴ 6s²'),
  ChemicalElement(atomicNumber: 61, symbol: 'Pm', name: 'Promethium', atomicMass: 145, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f⁵ 6s²', discoveryYear: '1945'),
  ChemicalElement(atomicNumber: 62, symbol: 'Sm', name: 'Samarium', atomicMass: 150.36, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f⁶ 6s²'),
  ChemicalElement(atomicNumber: 63, symbol: 'Eu', name: 'Europium', atomicMass: 151.96, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f⁷ 6s²'),
  ChemicalElement(atomicNumber: 64, symbol: 'Gd', name: 'Gadolinium', atomicMass: 157.25, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f⁷ 5d¹ 6s²'),
  ChemicalElement(atomicNumber: 65, symbol: 'Tb', name: 'Terbium', atomicMass: 158.93, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f⁹ 6s²'),
  ChemicalElement(atomicNumber: 66, symbol: 'Dy', name: 'Dysprosium', atomicMass: 162.50, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f¹⁰ 6s²'),
  ChemicalElement(atomicNumber: 67, symbol: 'Ho', name: 'Holmium', atomicMass: 164.93, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f¹¹ 6s²'),
  ChemicalElement(atomicNumber: 68, symbol: 'Er', name: 'Erbium', atomicMass: 167.26, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f¹² 6s²'),
  ChemicalElement(atomicNumber: 69, symbol: 'Tm', name: 'Thulium', atomicMass: 168.93, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f¹³ 6s²'),
  ChemicalElement(atomicNumber: 70, symbol: 'Yb', name: 'Ytterbium', atomicMass: 173.05, category: ElementCategory.lanthanide, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 6s²'),
  ChemicalElement(atomicNumber: 71, symbol: 'Lu', name: 'Lutetium', atomicMass: 174.97, category: ElementCategory.lanthanide, group: 3, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹ 6s²'),
  ChemicalElement(atomicNumber: 72, symbol: 'Hf', name: 'Hafnium', atomicMass: 178.49, category: ElementCategory.transitionMetal, group: 4, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d² 6s²'),
  ChemicalElement(atomicNumber: 73, symbol: 'Ta', name: 'Tantalum', atomicMass: 180.95, category: ElementCategory.transitionMetal, group: 5, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d³ 6s²'),
  ChemicalElement(atomicNumber: 74, symbol: 'W', name: 'Tungsten', atomicMass: 183.84, category: ElementCategory.transitionMetal, group: 6, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d⁴ 6s²'),
  ChemicalElement(atomicNumber: 75, symbol: 'Re', name: 'Rhenium', atomicMass: 186.21, category: ElementCategory.transitionMetal, group: 7, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d⁵ 6s²'),
  ChemicalElement(atomicNumber: 76, symbol: 'Os', name: 'Osmium', atomicMass: 190.23, category: ElementCategory.transitionMetal, group: 8, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d⁶ 6s²'),
  ChemicalElement(atomicNumber: 77, symbol: 'Ir', name: 'Iridium', atomicMass: 192.22, category: ElementCategory.transitionMetal, group: 9, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d⁷ 6s²'),
  ChemicalElement(atomicNumber: 78, symbol: 'Pt', name: 'Platinum', atomicMass: 195.08, category: ElementCategory.transitionMetal, group: 10, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d⁹ 6s¹'),
  ChemicalElement(atomicNumber: 79, symbol: 'Au', name: 'Gold', atomicMass: 196.97, category: ElementCategory.transitionMetal, group: 11, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹⁰ 6s¹'),
  ChemicalElement(atomicNumber: 80, symbol: 'Hg', name: 'Mercury', atomicMass: 200.59, category: ElementCategory.transitionMetal, group: 12, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹⁰ 6s²'),
  ChemicalElement(atomicNumber: 81, symbol: 'Tl', name: 'Thallium', atomicMass: 204.38, category: ElementCategory.postTransitionMetal, group: 13, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p¹'),
  ChemicalElement(atomicNumber: 82, symbol: 'Pb', name: 'Lead', atomicMass: 207.2, category: ElementCategory.postTransitionMetal, group: 14, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p²'),
  ChemicalElement(atomicNumber: 83, symbol: 'Bi', name: 'Bismuth', atomicMass: 208.98, category: ElementCategory.postTransitionMetal, group: 15, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p³'),
  ChemicalElement(atomicNumber: 84, symbol: 'Po', name: 'Polonium', atomicMass: 209, category: ElementCategory.metalloid, group: 16, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p⁴', discoveryYear: '1898'),
  ChemicalElement(atomicNumber: 85, symbol: 'At', name: 'Astatine', atomicMass: 210, category: ElementCategory.halogen, group: 17, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p⁵', discoveryYear: '1940'),
  ChemicalElement(atomicNumber: 86, symbol: 'Rn', name: 'Radon', atomicMass: 222, category: ElementCategory.nobleGas, group: 18, period: 6, electronConfiguration: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p⁶', discoveryYear: '1900'),
  ChemicalElement(atomicNumber: 87, symbol: 'Fr', name: 'Francium', atomicMass: 223, category: ElementCategory.alkaliMetal, group: 1, period: 7, electronConfiguration: '[Rn] 7s¹', discoveryYear: '1939'),
  ChemicalElement(atomicNumber: 88, symbol: 'Ra', name: 'Radium', atomicMass: 226, category: ElementCategory.alkalineEarthMetal, group: 2, period: 7, electronConfiguration: '[Rn] 7s²', discoveryYear: '1898'),
  ChemicalElement(atomicNumber: 89, symbol: 'Ac', name: 'Actinium', atomicMass: 227, category: ElementCategory.actinide, group: 3, period: 7, electronConfiguration: '[Rn] 6d¹ 7s²', discoveryYear: '1899'),
  ChemicalElement(atomicNumber: 90, symbol: 'Th', name: 'Thorium', atomicMass: 232.04, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 6d² 7s²', discoveryYear: '1829'),
  ChemicalElement(atomicNumber: 91, symbol: 'Pa', name: 'Protactinium', atomicMass: 231.04, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f² 6d¹ 7s²', discoveryYear: '1913'),
  ChemicalElement(atomicNumber: 92, symbol: 'U', name: 'Uranium', atomicMass: 238.03, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f³ 6d¹ 7s²', discoveryYear: '1789'),
  ChemicalElement(atomicNumber: 93, symbol: 'Np', name: 'Neptunium', atomicMass: 237, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f⁴ 6d¹ 7s²', discoveryYear: '1940'),
  ChemicalElement(atomicNumber: 94, symbol: 'Pu', name: 'Plutonium', atomicMass: 244, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f⁶ 7s²', discoveryYear: '1940'),
  ChemicalElement(atomicNumber: 95, symbol: 'Am', name: 'Americium', atomicMass: 243, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f⁷ 7s²', discoveryYear: '1944'),
  ChemicalElement(atomicNumber: 96, symbol: 'Cm', name: 'Curium', atomicMass: 247, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f⁷ 6d¹ 7s²', discoveryYear: '1944'),
  ChemicalElement(atomicNumber: 97, symbol: 'Bk', name: 'Berkelium', atomicMass: 247, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f⁹ 7s²', discoveryYear: '1949'),
  ChemicalElement(atomicNumber: 98, symbol: 'Cf', name: 'Californium', atomicMass: 251, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f¹⁰ 7s²', discoveryYear: '1950'),
  ChemicalElement(atomicNumber: 99, symbol: 'Es', name: 'Einsteinium', atomicMass: 252, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f¹¹ 7s²', discoveryYear: '1952'),
  ChemicalElement(atomicNumber: 100, symbol: 'Fm', name: 'Fermium', atomicMass: 257, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f¹² 7s²', discoveryYear: '1952'),
  ChemicalElement(atomicNumber: 101, symbol: 'Md', name: 'Mendelevium', atomicMass: 258, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f¹³ 7s²', discoveryYear: '1955'),
  ChemicalElement(atomicNumber: 102, symbol: 'No', name: 'Nobelium', atomicMass: 259, category: ElementCategory.actinide, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 7s²', discoveryYear: '1958'),
  ChemicalElement(atomicNumber: 103, symbol: 'Lr', name: 'Lawrencium', atomicMass: 262, category: ElementCategory.actinide, group: 3, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 7s² 7p¹', discoveryYear: '1961'),
  ChemicalElement(atomicNumber: 104, symbol: 'Rf', name: 'Rutherfordium', atomicMass: 267, category: ElementCategory.transitionMetal, group: 4, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d² 7s²', discoveryYear: '1969'),
  ChemicalElement(atomicNumber: 105, symbol: 'Db', name: 'Dubnium', atomicMass: 268, category: ElementCategory.transitionMetal, group: 5, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d³ 7s²', discoveryYear: '1967'),
  ChemicalElement(atomicNumber: 106, symbol: 'Sg', name: 'Seaborgium', atomicMass: 269, category: ElementCategory.transitionMetal, group: 6, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d⁴ 7s²', discoveryYear: '1974'),
  ChemicalElement(atomicNumber: 107, symbol: 'Bh', name: 'Bohrium', atomicMass: 270, category: ElementCategory.transitionMetal, group: 7, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d⁵ 7s²', discoveryYear: '1976'),
  ChemicalElement(atomicNumber: 108, symbol: 'Hs', name: 'Hassium', atomicMass: 277, category: ElementCategory.transitionMetal, group: 8, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d⁶ 7s²', discoveryYear: '1984'),
  ChemicalElement(atomicNumber: 109, symbol: 'Mt', name: 'Meitnerium', atomicMass: 278, category: ElementCategory.unknown, group: 9, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d⁷ 7s²', discoveryYear: '1982'),
  ChemicalElement(atomicNumber: 110, symbol: 'Ds', name: 'Darmstadtium', atomicMass: 281, category: ElementCategory.unknown, group: 10, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d⁸ 7s²', discoveryYear: '1994'),
  ChemicalElement(atomicNumber: 111, symbol: 'Rg', name: 'Roentgenium', atomicMass: 282, category: ElementCategory.unknown, group: 11, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d⁹ 7s²', discoveryYear: '1994'),
  ChemicalElement(atomicNumber: 112, symbol: 'Cn', name: 'Copernicium', atomicMass: 285, category: ElementCategory.unknown, group: 12, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d¹⁰ 7s²', discoveryYear: '1996'),
  ChemicalElement(atomicNumber: 113, symbol: 'Nh', name: 'Nihonium', atomicMass: 286, category: ElementCategory.unknown, group: 13, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p¹', discoveryYear: '2004'),
  ChemicalElement(atomicNumber: 114, symbol: 'Fl', name: 'Flerovium', atomicMass: 289, category: ElementCategory.unknown, group: 14, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p²', discoveryYear: '1998'),
  ChemicalElement(atomicNumber: 115, symbol: 'Mc', name: 'Moscovium', atomicMass: 290, category: ElementCategory.unknown, group: 15, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p³', discoveryYear: '2003'),
  ChemicalElement(atomicNumber: 116, symbol: 'Lv', name: 'Livermorium', atomicMass: 293, category: ElementCategory.unknown, group: 16, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p⁴', discoveryYear: '2000'),
  ChemicalElement(atomicNumber: 117, symbol: 'Ts', name: 'Tennessine', atomicMass: 294, category: ElementCategory.unknown, group: 17, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p⁵', discoveryYear: '2010'),
  ChemicalElement(atomicNumber: 118, symbol: 'Og', name: 'Oganesson', atomicMass: 294, category: ElementCategory.unknown, group: 18, period: 7, electronConfiguration: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p⁶', discoveryYear: '2006'),
];

String getCategoryName(ElementCategory category) {
  switch (category) {
    case ElementCategory.alkaliMetal:
      return 'Alkali Metal';
    case ElementCategory.alkalineEarthMetal:
      return 'Alkaline Earth Metal';
    case ElementCategory.transitionMetal:
      return 'Transition Metal';
    case ElementCategory.postTransitionMetal:
      return 'Post-Transition Metal';
    case ElementCategory.metalloid:
      return 'Metalloid';
    case ElementCategory.nonmetal:
      return 'Nonmetal';
    case ElementCategory.halogen:
      return 'Halogen';
    case ElementCategory.nobleGas:
      return 'Noble Gas';
    case ElementCategory.lanthanide:
      return 'Lanthanide';
    case ElementCategory.actinide:
      return 'Actinide';
    case ElementCategory.unknown:
      return 'Unknown';
  }
}

Color getCategoryColor(ElementCategory category, ColorScheme colorScheme) {
  switch (category) {
    case ElementCategory.alkaliMetal:
      return Color(0xFFE57373);
    case ElementCategory.alkalineEarthMetal:
      return Color(0xFFFFB74D);
    case ElementCategory.transitionMetal:
      return Color(0xFF64B5F6);
    case ElementCategory.postTransitionMetal:
      return Color(0xFF4DD0E1);
    case ElementCategory.metalloid:
      return Color(0xFF81C784);
    case ElementCategory.nonmetal:
      return Color(0xFFAED581);
    case ElementCategory.halogen:
      return Color(0xFFFF8A65);
    case ElementCategory.nobleGas:
      return Color(0xFFBA68C8);
    case ElementCategory.lanthanide:
      return Color(0xFFFFF176);
    case ElementCategory.actinide:
      return Color(0xFFF48FB1);
    case ElementCategory.unknown:
      return colorScheme.surfaceContainerHighest;
  }
}

class PeriodicTableModel extends ChangeNotifier {
  bool _initialized = false;
  String _searchQuery = '';
  ChemicalElement? _selectedElement;
  ElementCategory? _selectedCategory;
  
  bool get initialized => _initialized;
  String get searchQuery => _searchQuery;
  ChemicalElement? get selectedElement => _selectedElement;
  ElementCategory? get selectedCategory => _selectedCategory;
  List<ChemicalElement> get allElements => chemicalElements;
  
  List<ChemicalElement> get filteredElements {
    var elements = chemicalElements;
    
    if (_selectedCategory != null) {
      elements = elements.where((e) => e.category == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      elements = elements.where((e) =>
        e.name.toLowerCase().contains(query) ||
        e.symbol.toLowerCase().contains(query) ||
        e.atomicNumber.toString().contains(query)
      ).toList();
    }
    
    return elements;
  }
  
  void init() {
    if (!_initialized) {
      _initialized = true;
      Global.loggerModel.info("PeriodicTable initialized", source: "PeriodicTable");
      notifyListeners();
    }
  }
  
  void refresh() {
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void setSelectedElement(ChemicalElement? element) {
    _selectedElement = element;
    notifyListeners();
    if (element != null) {
      Global.loggerModel.info("Element selected: ${element.symbol}", source: "PeriodicTable");
    }
  }
  
  void setSelectedCategory(ElementCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedElement = null;
    notifyListeners();
  }
  
  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class PeriodicTableCard extends StatefulWidget {
  @override
  State<PeriodicTableCard> createState() => _PeriodicTableCardState();
}

class _PeriodicTableCardState extends State<PeriodicTableCard> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final model = context.watch<PeriodicTableModel>();
    
    if (!model.initialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.science, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Text('Periodic Table', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              SizedBox(height: 12),
              _buildSearchField(context, model),
              SizedBox(height: 8),
              _buildCategoryFilter(context, model),
              SizedBox(height: 12),
              if (model.selectedElement != null)
                _buildElementDetail(context, model)
              else
                _buildElementGrid(context, model),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchField(BuildContext context, PeriodicTableModel model) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search elements (name, symbol, number)',
        prefixIcon: Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                model.setSearchQuery('');
              },
            )
          : null,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => model.setSearchQuery(value),
    );
  }
  
  Widget _buildCategoryFilter(BuildContext context, PeriodicTableModel model) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            label: Text('All'),
            onPressed: () => model.setSelectedCategory(null),
            backgroundColor: model.selectedCategory == null
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          ),
          SizedBox(width: 4),
          ...ElementCategory.values.map((category) => Padding(
            padding: EdgeInsets.only(left: 4),
            child: ActionChip(
              label: Text(getCategoryName(category).split(' ').first),
              onPressed: () => model.setSelectedCategory(category),
              backgroundColor: model.selectedCategory == category
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildElementGrid(BuildContext context, PeriodicTableModel model) {
    final elements = model.filteredElements;
    
    if (elements.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text('No elements found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: elements.length > 36 ? 36 : elements.length,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final element = elements[index];
        return _buildElementTile(context, model, element);
      },
    );
  }
  
  Widget _buildElementTile(BuildContext context, PeriodicTableModel model, ChemicalElement element) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getCategoryColor(element.category, colorScheme);
    
    return GestureDetector(
      onTap: () => model.setSelectedElement(element),
      child: Container(
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              element.atomicNumber.toString(),
              style: TextStyle(fontSize: 8, color: colorScheme.onSurface),
            ),
            Text(
              element.symbol,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildElementDetail(BuildContext context, PeriodicTableModel model) {
    final element = model.selectedElement!;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getCategoryColor(element.category, colorScheme);
    
    return Card(
      color: categoryColor.withValues(alpha: 0.3),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        element.symbol,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(element.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(getCategoryName(element.category), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => model.clearSelection(),
                  tooltip: 'Close detail',
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(context, 'Atomic #', '${element.atomicNumber}'),
                _buildInfoChip(context, 'Mass', '${element.atomicMass}'),
                if (element.group != null)
                  _buildInfoChip(context, 'Group', '${element.group}'),
                if (element.period != null)
                  _buildInfoChip(context, 'Period', '${element.period}'),
                if (element.discoveryYear != null)
                  _buildInfoChip(context, 'Discovered', element.discoveryYear!),
              ],
            ),
            if (element.electronConfiguration != null) ...[
              SizedBox(height: 8),
              Text('Electron Config:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              SelectableText(
                element.electronConfiguration!,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    final text = '${element.name} (${element.symbol})\nAtomic Number: ${element.atomicNumber}\nAtomic Mass: ${element.atomicMass}';
                    model.copyToClipboard(text, context);
                  },
                  child: Text('Copy Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}