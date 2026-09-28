import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/doctor_card.dart';
import '../../widgets/empty_view.dart';

/// Admin Screen displaying the medical staff and specialist doctor roster.
class DoctorRosterScreen extends StatefulWidget {
  const DoctorRosterScreen({super.key});

  @override
  State<DoctorRosterScreen> createState() => _DoctorRosterScreenState();
}

class _DoctorRosterScreenState extends State<DoctorRosterScreen> {
  String? _selectedDepartment;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apptProv = context.watch<AppointmentProvider>();
    final doctors = apptProv.doctors;

    final departments = doctors.map((d) => d.department).toSet().toList()..sort();

    final filtered = _selectedDepartment == null
        ? doctors
        : doctors.where((d) => d.department == _selectedDepartment).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Staff Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => apptProv.loadData(auth.currentUser),
          ),
        ],
      ),
      body: Column(
        children: [
          // Department Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All Departments'),
                    selected: _selectedDepartment == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDepartment = null);
                    },
                  ),
                ),
                ...departments.map((dept) {
                  final isSelected = _selectedDepartment == dept;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(dept),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedDepartment = selected ? dept : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Doctors List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => apptProv.loadData(auth.currentUser),
              child: filtered.isEmpty
                  ? const Center(
                      child: EmptyView(
                        title: 'No Doctors Found',
                        message: 'No doctors are currently registered under this department.',
                        icon: Icons.medical_services_outlined,
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DoctorCard(
                            doctor: doc,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
