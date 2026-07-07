import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/customer_entity.dart';
import '../domain/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CustomerRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<CustomerEntity>> watchCustomers(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customers')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomerEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<CustomerEntity>> getCustomers(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => CustomerEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<CustomerEntity?> getCustomerById(
      String companyId, String customerId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .doc(customerId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return CustomerEntity.fromMap(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<CustomerEntity> createCustomer(
      String companyId, CustomerEntity customer) async {
    try {
      final id = customer.id.isEmpty ? _uuid.v4() : customer.id;
      final newCustomer = customer.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .doc(id)
          .set(newCustomer.toMap());

      return newCustomer;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateCustomer(String companyId, CustomerEntity customer) async {
    try {
      final updatedCustomer = customer.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .doc(customer.id)
          .update(updatedCustomer.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteCustomer(String companyId, String customerId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .doc(customerId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
