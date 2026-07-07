import 'customer_entity.dart';

abstract class CustomerRepository {
  Stream<List<CustomerEntity>> watchCustomers(String companyId);
  Future<List<CustomerEntity>> getCustomers(String companyId);
  Future<CustomerEntity?> getCustomerById(String companyId, String customerId);
  Future<CustomerEntity> createCustomer(
      String companyId, CustomerEntity customer);
  Future<void> updateCustomer(String companyId, CustomerEntity customer);
  Future<void> deleteCustomer(String companyId, String customerId);
}
