part of 'organisations_bloc.dart';

@immutable
sealed class OrganisationsEvent {}

class CreateOrganisationEvent extends OrganisationsEvent {
  final String name;
  final String description;

  CreateOrganisationEvent({required this.name, required this.description});
}
