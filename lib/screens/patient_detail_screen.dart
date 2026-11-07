// lib/screens/patient_detail_screen.dart

import 'package:flutter/material.dart';
import '../mock/mock_data.dart';
import '../models/patient.dart';
import 'register_encounter_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  // En Entrega 2 los datos viven en memoria (AD-02)
  late Patient patient;
  int _currentTabIndex = 1; // Tab 'Pacientes' activo por defecto

  @override
  void initState() {
    super.initState();
    patient = MockData.jorgePardo;
  }

  void _navigateToRegisterEncounter() async {
    final newEncounter = await Navigator.push<Encounter>(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterEncounterScreen(patient: patient),
      ),
    );

    if (newEncounter != null) {
      setState(() {
        patient = Patient(
          id: patient.id,
          fullName: patient.fullName,
          age: patient.age,
          sex: patient.sex,
          documentType: patient.documentType,
          documentNumber: patient.documentNumber,
          birthDate: patient.birthDate,
          address: patient.address,
          systemIdentifiers: patient.systemIdentifiers,
          readmissionRisk: patient.readmissionRisk,
          encounters: [newEncounter, ...patient.encounters],
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atención registrada exitosamente en su historia unificada'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final risk = patient.readmissionRisk;

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
              const SizedBox(height: 12),
              _buildUnifiedHeaderCard(),
              const SizedBox(height: 16),
              if (risk != null) ...[
                _buildRiskSection(risk),
                const SizedBox(height: 16),
              ],
              _buildEncountersSection(),
              const SizedBox(height: 16),
              _buildBasicInfoSection(),
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
      titleSpacing: 16,
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
            text: patient.fullName,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF241468),
            Color(0xFF381A90),
            Color(0xFF5B21B6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTORIA CLÍNICA UNIFICADA',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            patient.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderChip('${patient.age} años · ${patient.sex}'),
              _buildHeaderChip(patient.documentDisplay),
              _buildHeaderChip(
                patient.systemIdentifiers.map((e) => e.systemName).join(' · '),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444), width: 5),
                color: const Color(0xFF1E1035).withValues(alpha: 0.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patient.readmissionRisk != null
                        ? patient.readmissionRisk!.score.toStringAsFixed(1).replaceAll('.', ',')
                        : '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'CON ALERTA',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Esta consulta se audita · Propósito: Seguimiento de reingreso · 10:43',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToRegisterEncounter,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'Registrar atención',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRiskSection(ReadmissionRisk risk) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riesgo de reingreso a 30 días',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Apoyo a la decisión clínica. Estimación estadística del modelo, no es un diagnóstico.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          if (risk.isHighRisk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Con alerta de alto riesgo · ${risk.score.toStringAsFixed(1).replaceAll('.', ',')} (umbral ${risk.threshold.toInt()})',
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'Calculado el 21 oct 2026 · ${risk.periodDescription}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const Divider(height: 28, color: Color(0xFFE5E7EB)),
          const Text(
            'Qué explica este riesgo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coral: sube el riesgo · verde: lo baja. Cada barra son puntos del puntaje.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          ...risk.factors.map(_buildFactorItem),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF4F46E5)),
                SizedBox(width: 4),
                Text(
                  'Cómo se calcula',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorItem(RiskFactor factor) {
    final isIncrease = factor.impact == RiskFactorImpact.sube;
    final color = isIncrease ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final scoreNormalized = (factor.points / 30.0).clamp(0.1, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 13,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  factor.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Text(
                '${isIncrease ? "Sube" : "Baja"} +${factor.points.toStringAsFixed(1).replaceAll('.', ',')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 5,
                        color: const Color(0xFFF3F4F6),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: scoreNormalized,
                          child: Container(color: color.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      factor.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEncountersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Atenciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '${patient.encounters.length} registros',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (patient.encounters.isEmpty)
            const Text(
              'Este paciente no tiene atenciones registradas',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: patient.encounters.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildEncounterCard(patient.encounters[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEncounterCard(Encounter enc) {
    final isHosp = enc.type == EncounterType.hospitalizacion;
    final dotColor = isHosp ? const Color(0xFF06B6D4) : const Color(0xFF10B981);

    String dateLine = '';
    if (enc.endDate != null && enc.startDate != enc.endDate) {
      dateLine =
          '${_formatShortDate(enc.startDate)} - ${_formatShortDate(enc.endDate!)} · ${enc.lengthOfStayDays ?? 0} d';
    } else {
      dateLine = '${_formatShortDate(enc.startDate)} · Mismo día';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                enc.typeLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  enc.statusLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            enc.facilityName,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 2),
          Text(
            dateLine,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 2),
          Text(
            'Destino: ${enc.dischargeDestination} · ${enc.doctorName}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoField('EDAD Y SEXO', '${patient.age} años · ${patient.sex}'),
          const SizedBox(height: 12),
          _buildInfoField('FECHA DE NACIMIENTO', _formatShortDate(patient.birthDate)),
          const SizedBox(height: 12),
          _buildInfoField('DIRECCIÓN', patient.address),
          const SizedBox(height: 12),
          const Text(
            'IDENTIFICADORES POR SISTEMA DE ORIGEN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          ...patient.systemIdentifiers.map(
            (id) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${id.systemName} · ${id.identifier}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Mostrar documentos',
              style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
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

  String _formatShortDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
