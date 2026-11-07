// lib/screens/register_encounter_screen.dart

import 'package:flutter/material.dart';
import '../mock/mock_data.dart';
import '../models/patient.dart';

class RegisterEncounterScreen extends StatefulWidget {
  final Patient patient;

  const RegisterEncounterScreen({
    super.key,
    required this.patient,
  });

  @override
  State<RegisterEncounterScreen> createState() => _RegisterEncounterScreenState();
}

class _RegisterEncounterScreenState extends State<RegisterEncounterScreen> {
  final _formKey = GlobalKey<FormState>();

  EncounterType _selectedType = EncounterType.hospitalizacion;
  String _selectedFacility = MockData.availableFacilities.first;
  String _selectedDischargeDestination = MockData.dischargeDestinations.first;

  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  int _currentTabIndex = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDateController = TextEditingController(text: _formatDate(now));
    _endDateController = TextEditingController();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _saveEncounter() {
    // Generar la atención simulada
    final newEncounter = Encounter(
      id: 'enc-${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedType,
      status: _endDateController.text.trim().isNotEmpty
          ? EncounterStatus.finalizada
          : EncounterStatus.enCurso,
      facilityName: _selectedFacility,
      startDate: DateTime.now(),
      endDate: _endDateController.text.trim().isNotEmpty ? DateTime.now() : null,
      lengthOfStayDays: _endDateController.text.trim().isNotEmpty ? 1 : 0,
      dischargeDestination: _selectedDischargeDestination,
      doctorName: 'Dra. Camila Martínez',
      reason: 'Atención médica general',
      diagnosis: 'Sin complicaciones reportadas',
    );

    Navigator.pop(context, newEncounter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: _buildTopBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBreadcrumb(),
              const SizedBox(height: 16),
              Text(
                'NUEVA ATENCIÓN',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Registrar atención de\n${widget.patient.fullName.split(" ").take(2).join(" ")}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Si indica la fecha de alta y el destino, el sistema recalcula el riesgo de reingreso.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              _buildFormCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hub_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          const Text(
            'Red Vitalys',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF4338CA),
            child: const Text(
              'CM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Pacientes  /  ',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          TextSpan(
            text: '${widget.patient.fullName}  /  ',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const TextSpan(
            text: 'Registrar atención',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tipo de atención',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            _buildEncounterTypeOption(
              type: EncounterType.hospitalizacion,
              label: 'Hospitalización',
              icon: Icons.hotel_outlined,
            ),
            const SizedBox(height: 8),
            _buildEncounterTypeOption(
              type: EncounterType.urgencias,
              label: 'Urgencias',
              icon: Icons.bolt_outlined,
            ),
            const SizedBox(height: 8),
            _buildEncounterTypeOption(
              type: EncounterType.consultaExterna,
              label: 'Consulta externa',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 18),
            const Text(
              'Sede',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedFacility,
              decoration: _inputDecoration(),
              items: MockData.availableFacilities.map((facility) {
                return DropdownMenuItem(
                  value: facility,
                  child: Text(facility, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedFacility = val);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Fecha de inicio',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _startDateController,
              decoration: _inputDecoration(),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fecha de alta (opcional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Déjelo vacío si el paciente sigue en atención',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _endDateController,
              decoration: _inputDecoration(hintText: 'Ej. 14 oct 2026'),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Destino al alta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedDischargeDestination,
              decoration: _inputDecoration(),
              items: MockData.dischargeDestinations.map((dest) {
                return DropdownMenuItem(
                  value: dest,
                  child: Text(dest, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedDischargeDestination = val);
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveEncounter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Guardar atención',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncounterTypeOption({
    required EncounterType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() => _selectedType = type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) {
        setState(() {
          _currentTabIndex = index;
        });
      },
      selectedItemColor: const Color(0xFF1E1B4B),
      unselectedItemColor: const Color(0xFF9CA3AF),
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Pacientes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Indicadores',
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
