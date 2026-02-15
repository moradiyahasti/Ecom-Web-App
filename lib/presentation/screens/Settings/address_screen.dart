/* import 'dart:convert';
import 'dart:developer';
import 'package:demo/data/models/get_cart_item_model.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/presentation/screens/Settings/payment_screen.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:demo/data/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// 📦 Address Model
class SavedAddress {
  final int id;
  final String name;
  final String mobile;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String? addressType;

  SavedAddress({
    required this.id,
    required this.name,
    required this.mobile,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.addressType,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] ?? json['address_id'],
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? json['phone'] ?? '',
      addressLine: json['address_line'] ?? json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? json['pin_code'] ?? '',
      addressType: json['address_type'] ?? json['type'],
    );
  }

  String get fullAddress => '$addressLine, $city, $state - $pincode';
}

class AddressScreen extends StatefulWidget {
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final List<GetCartItemMode> cartItems;

  const AddressScreen({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.cartItems,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _buttonController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonScale;

  int? userId;
  String? userName;
  bool _isLoading = false;
  bool _isLoadingAddresses = false;
  bool _showAddNewAddress = false;

  List<SavedAddress> _savedAddresses = [];
  int? _selectedAddressId;
  String _selectedAddressType = 'home';

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _pincodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    loadUserId();
    _loadSavedAddresses();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> loadUserId() async {
    final id = await TokenService.getUserId();
    final name = await TokenService.getName();

    log("👤 LOGGED IN USER ID: $id");
    log("👤 LOGGED IN USER NAME: $name");

    setState(() {
      userId = id;
      userName = name;
    });
  }

  Future<void> _loadSavedAddresses() async {
    if (userId == null) {
      await loadUserId();
      if (userId == null) return;
    }

    setState(() => _isLoadingAddresses = true);

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/addresses/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      log("⬅️ FETCH ADDRESSES STATUS: ${response.statusCode}");
      log("⬅️ FETCH ADDRESSES RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        dynamic data;
        if (responseBody.startsWith('[')) {
          data = jsonDecode(responseBody);
        } else {
          data = jsonDecode(responseBody);
          data = data['addresses'] ?? data['data'] ?? [];
        }

        final List addressList = data is List ? data : [];

        setState(() {
          _savedAddresses = addressList
              .map((addr) => SavedAddress.fromJson(addr))
              .toList();

          log("📍 LOADED ${_savedAddresses.length} SAVED ADDRESSES");

          if (_savedAddresses.isNotEmpty) {
            _showAddNewAddress = false;
            _selectedAddressId = _savedAddresses.first.id;
            log("✅ Showing saved addresses (${_savedAddresses.length} found)");
          } else {
            _showAddNewAddress = true;
            log("ℹ️ No saved addresses found, showing new address form");
          }
        });
      } else {
        log("⚠️ Non-200 response, showing new address form");
        setState(() => _showAddNewAddress = true);
      }
    } catch (e) {
      log("❌ ERROR LOADING ADDRESSES: $e");
      if (_savedAddresses.isEmpty) {
        setState(() => _showAddNewAddress = true);
      }
    } finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _pincodeFocus.dispose();

    _slideController.dispose();
    _fadeController.dispose();
    _buttonController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildOrderSummaryCard(),
                        const SizedBox(height: 24),

                        if (_isLoadingAddresses)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_showAddNewAddress)
                          _buildAddressForm()
                        else
                          _buildSavedAddressesList(),

                        const SizedBox(height: 24),
                        _buildContinueButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.deepPurple.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Delivery Address',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAddNewAddress = true;
                    _nameController.clear();
                    _phoneController.clear();
                    _addressController.clear();
                    _cityController.clear();
                    _stateController.clear();
                    _pincodeController.clear();
                    _selectedAddressType = 'home';
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add New',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._savedAddresses.map((address) => _buildAddressCard(address)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress address) {
    final isSelected = _selectedAddressId == address.id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedAddressId = address.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurple.shade600
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<int>(
              value: address.id,
              groupValue: _selectedAddressId,
              activeColor: Colors.deepPurple.shade600,
              onChanged: (value) {
                setState(() => _selectedAddressId = value);
              },
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (address.addressType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getAddressTypeColor(address.addressType!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            address.addressType!.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.mobile,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address.fullAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAddressTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Colors.deepPurple.shade400;
      case 'work':
        return Colors.orange.shade400;
      case 'office':
        return Colors.blue.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade50, Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.location_on,
                  size: 36,
                  color: Colors.deepPurple.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery Address',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.deepPurple.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Step 2 of 3',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Where should we deliver?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _showAddNewAddress
              ? 'Please provide your delivery address details'
              : 'Choose from saved addresses or add a new one',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.cartItems.length} Items',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.total.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem('Subtotal', widget.subtotal),
                _summaryItem('Tax', widget.tax),
                _summaryItem('Shipping', widget.shipping),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_location_alt,
                      color: Colors.deepPurple.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Address Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              if (_savedAddresses.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showAddNewAddress = false);
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text('Back', style: GoogleFonts.poppins(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Address Type',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _addressTypeChip('home', 'Home', Icons.home),
              const SizedBox(width: 10),
              _addressTypeChip('work', 'Work', Icons.work),
              const SizedBox(width: 10),
              _addressTypeChip('other', 'Other', Icons.location_on),
            ],
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            focusNode: _nameFocus,
            nextFocus: _phoneFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Mobile Number',
            icon: Icons.phone_outlined,
            isNumber: true,
            focusNode: _phoneFocus,
            nextFocus: _addressFocus,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Mobile number is required';
              }
              if (value.length != 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'House No, Building, Street',
            icon: Icons.home_outlined,
            maxLines: 3,
            focusNode: _addressFocus,
            nextFocus: _cityFocus,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  focusNode: _cityFocus,
                  nextFocus: _stateFocus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  icon: Icons.map_outlined,
                  focusNode: _stateFocus,
                  nextFocus: _pincodeFocus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _pincodeController,
            label: 'Pincode',
            icon: Icons.pin_drop_outlined,
            isNumber: true,
            focusNode: _pincodeFocus,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Pincode is required';
              }
              if (value.length != 6) {
                return 'Please enter a valid 6-digit pincode';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _addressTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedAddressType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedAddressType = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurple.shade600
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.deepPurple.shade600
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
        prefixIcon: Icon(icon, size: 20, color: Colors.deepPurple.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.red.shade600,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return ScaleTransition(
      scale: _buttonScale,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade500, Colors.deepPurple.shade700],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue to Payment',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<int?> _createOrder(int addressId) async {
    try {
      final orderData = {
        "user_id": userId,
        "address_id": addressId,
        "total": widget.total,
        "items": widget.cartItems
            .map(
              (e) => {
                "product_id": e.productId,
                "qty": e.quantity,
                "price": e.price,
              },
            )
            .toList(),
      };

      log("📦 CREATING ORDER: ${jsonEncode(orderData)}");

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/orders/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(orderData),
      );

      log("⬅️ CREATE ORDER STATUS: ${response.statusCode}");
      log("⬅️ CREATE ORDER RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['order_id'];
      }

      return null;
    } catch (e) {
      log("❌ CREATE ORDER ERROR: $e");
      return null;
    }
  }

  // 🔥🔥🔥 CRITICAL FIX: Properly handle return from payment screen
  Future<void> _handleContinue() async {
    _buttonController.forward().then((_) => _buttonController.reverse());

    if (userId == null) {
      _showErrorSnackbar('User not logged in');
      return;
    }

    setState(() => _isLoading = true);

    try {
      int? addressId;

      // 🔥 IF USING SAVED ADDRESS
      if (!_showAddNewAddress && _selectedAddressId != null) {
        addressId = _selectedAddressId;
        log("📍 USING SAVED ADDRESS ID: $addressId");
      }
      // 🔥 IF ADDING NEW ADDRESS
      else {
        if (!_formKey.currentState!.validate()) {
          setState(() => _isLoading = false);
          _showErrorSnackbar('Please fill all required fields correctly');
          return;
        }

        final response = await http.post(
          Uri.parse("${ApiService.baseUrl}/api/addresses/save"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "name": _nameController.text.trim(),
            "mobile": _phoneController.text.trim(),
            "address_line": _addressController.text.trim(),
            "city": _cityController.text.trim(),
            "state": _stateController.text.trim(),
            "pincode": _pincodeController.text.trim(),
            "address_type": _selectedAddressType,
          }),
        );

        log("📍 SAVE ADDRESS RESPONSE: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          addressId = data['address_id'] ?? data['id'];
          log("📍 NEW ADDRESS SAVED ID: $addressId");

          await _loadSavedAddresses();
        } else {
          throw Exception("Failed to save address");
        }
      }

      if (addressId == null) {
        throw Exception("No address selected or saved");
      }

      // 2️⃣ Create order
      final orderId = await _createOrder(addressId);

      if (orderId == null) {
        throw Exception("Failed to create order");
      }

      log("📦 CREATED ORDER ID: $orderId");

      setState(() => _isLoading = false);

      _showSuccessSnackbar('Address confirmed successfully');

      // 🔥 START PAYMENT FLOW
      if (mounted) {
        await context.read<CartProvider>().startPaymentFlow();
        log("🔒 Payment flow started - cart reloads now BLOCKED");
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 3️⃣ Navigate to payment
      final result = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PaymentScreen(
                totalAmount: widget.total,
                orderDetails: {
                  "order_id": orderId,
                  "user_id": userId,
                  "address_id": addressId,
                  "subtotal": widget.subtotal,
                  "tax": widget.tax,
                  "shipping": widget.shipping,
                  "discount": widget.discount,
                  "total": widget.total,
                  "cart_items": widget.cartItems
                      .map(
                        (e) => {
                          "product_id": e.productId,
                          "qty": e.quantity,
                          "price": e.price,
                        },
                      )
                      .toList(),
                },
                // orderId: orderId.toString(),
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );

      // 🔥🔥🔥 CRITICAL FIX: Handle return from payment screen
      if (mounted) {
        print("═══════════════════════════════════════════");
        print("⬅️ RETURNED FROM PAYMENT SCREEN");
        print("───────────────────────────────────────────");

        final cartProvider = context.read<CartProvider>();
        final paymentInProgress = await cartProvider.isPaymentInProgress;

        print("🔍 Checking payment flag: $paymentInProgress");

        if (paymentInProgress) {
          // User returned WITHOUT completing payment
          print("💡 User didn't complete payment - clearing flag");
          await cartProvider.endPaymentFlow();
          print("🔓 Payment flow ended");
          print("ℹ️ Cart screen will auto-reload when shown");
        } else {
          // Payment was completed successfully
          print("✅ Payment was completed - cart already cleared");
        }

        print("═══════════════════════════════════════════");
        log("⬅️ Returned from payment - flag handled");
      }
    } catch (e) {
      log("❌ ERROR: $e");
      setState(() => _isLoading = false);

      // 🔥 END PAYMENT FLOW on error
      if (mounted) {
        final cartProvider = context.read<CartProvider>();
        final paymentInProgress = await cartProvider.isPaymentInProgress;

        if (paymentInProgress) {
          await cartProvider.endPaymentFlow();
          log("🔓 Payment flow ended - error occurred");
        }
      }

      _showErrorSnackbar('Failed: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
 */

import 'dart:convert';
import 'dart:developer';
import 'package:demo/data/models/get_cart_item_model.dart';
import 'package:demo/data/providers/cart_provider.dart';
// ✅ CHANGE 1: payment_proff.dart import (tmare file naam same rakho)
import 'package:demo/presentation/screens/Settings/payment_proff.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:demo/data/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// 📦 Address Model
class SavedAddress {
  final int id;
  final String name;
  final String mobile;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String? addressType;

  SavedAddress({
    required this.id,
    required this.name,
    required this.mobile,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.addressType,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] ?? json['address_id'],
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? json['phone'] ?? '',
      addressLine: json['address_line'] ?? json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? json['pin_code'] ?? '',
      addressType: json['address_type'] ?? json['type'],
    );
  }

  String get fullAddress => '$addressLine, $city, $state - $pincode';
}

class AddressScreen extends StatefulWidget {
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final List<GetCartItemMode> cartItems;

  const AddressScreen({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.cartItems,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _buttonController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonScale;

  int? userId;
  String? userName;
  bool _isLoading = false;
  bool _isLoadingAddresses = false;
  bool _showAddNewAddress = false;

  List<SavedAddress> _savedAddresses = [];
  int? _selectedAddressId;
  String _selectedAddressType = 'home';

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _pincodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    loadUserId();
    _loadSavedAddresses();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> loadUserId() async {
    final id = await TokenService.getUserId();
    final name = await TokenService.getName();

    log("👤 LOGGED IN USER ID: $id");
    log("👤 LOGGED IN USER NAME: $name");

    setState(() {
      userId = id;
      userName = name;
    });
  }

  Future<void> _loadSavedAddresses() async {
    if (userId == null) {
      await loadUserId();
      if (userId == null) return;
    }

    setState(() => _isLoadingAddresses = true);

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/addresses/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      log("⬅️ FETCH ADDRESSES STATUS: ${response.statusCode}");
      log("⬅️ FETCH ADDRESSES RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        dynamic data;
        if (responseBody.startsWith('[')) {
          data = jsonDecode(responseBody);
        } else {
          data = jsonDecode(responseBody);
          data = data['addresses'] ?? data['data'] ?? [];
        }

        final List addressList = data is List ? data : [];

        setState(() {
          _savedAddresses = addressList
              .map((addr) => SavedAddress.fromJson(addr))
              .toList();

          log("📍 LOADED ${_savedAddresses.length} SAVED ADDRESSES");

          if (_savedAddresses.isNotEmpty) {
            _showAddNewAddress = false;
            _selectedAddressId = _savedAddresses.first.id;
          } else {
            _showAddNewAddress = true;
          }
        });
      } else {
        setState(() => _showAddNewAddress = true);
      }
    } catch (e) {
      log("❌ ERROR LOADING ADDRESSES: $e");
      if (_savedAddresses.isEmpty) {
        setState(() => _showAddNewAddress = true);
      }
    } finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _pincodeFocus.dispose();

    _slideController.dispose();
    _fadeController.dispose();
    _buttonController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildOrderSummaryCard(),
                        const SizedBox(height: 24),

                        if (_isLoadingAddresses)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_showAddNewAddress)
                          _buildAddressForm()
                        else
                          _buildSavedAddressesList(),

                        const SizedBox(height: 24),
                        _buildContinueButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.deepPurple.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Delivery Address',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAddNewAddress = true;
                    _nameController.clear();
                    _phoneController.clear();
                    _addressController.clear();
                    _cityController.clear();
                    _stateController.clear();
                    _pincodeController.clear();
                    _selectedAddressType = 'home';
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add New',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._savedAddresses.map((address) => _buildAddressCard(address)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress address) {
    final isSelected = _selectedAddressId == address.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = address.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurple.shade600
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<int>(
              value: address.id,
              groupValue: _selectedAddressId,
              activeColor: Colors.deepPurple.shade600,
              onChanged: (value) => setState(() => _selectedAddressId = value),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (address.addressType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getAddressTypeColor(address.addressType!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            address.addressType!.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.mobile,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address.fullAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAddressTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Colors.deepPurple.shade400;
      case 'work':
        return Colors.orange.shade400;
      case 'office':
        return Colors.blue.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade50, Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.location_on,
                  size: 36,
                  color: Colors.deepPurple.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery Address',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.deepPurple.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Step 2 of 3',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Where should we deliver?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _showAddNewAddress
              ? 'Please provide your delivery address details'
              : 'Choose from saved addresses or add a new one',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.cartItems.length} Items',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.total.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem('Subtotal', widget.subtotal),
                _summaryItem('Tax', widget.tax),
                _summaryItem('Shipping', widget.shipping),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_location_alt,
                      color: Colors.deepPurple.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Address Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              if (_savedAddresses.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _showAddNewAddress = false),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text('Back', style: GoogleFonts.poppins(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Address Type',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _addressTypeChip('home', 'Home', Icons.home),
              const SizedBox(width: 10),
              _addressTypeChip('work', 'Work', Icons.work),
              const SizedBox(width: 10),
              _addressTypeChip('other', 'Other', Icons.location_on),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            focusNode: _nameFocus,
            nextFocus: _phoneFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Mobile Number',
            icon: Icons.phone_outlined,
            isNumber: true,
            focusNode: _phoneFocus,
            nextFocus: _addressFocus,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return 'Mobile number is required';
              if (value.length != 10)
                return 'Please enter a valid 10-digit mobile number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'House No, Building, Street',
            icon: Icons.home_outlined,
            maxLines: 3,
            focusNode: _addressFocus,
            nextFocus: _cityFocus,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  focusNode: _cityFocus,
                  nextFocus: _stateFocus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  icon: Icons.map_outlined,
                  focusNode: _stateFocus,
                  nextFocus: _pincodeFocus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _pincodeController,
            label: 'Pincode',
            icon: Icons.pin_drop_outlined,
            isNumber: true,
            focusNode: _pincodeFocus,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return 'Pincode is required';
              if (value.length != 6)
                return 'Please enter a valid 6-digit pincode';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _addressTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedAddressType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAddressType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurple.shade600
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.deepPurple.shade600
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
      },
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty)
              return '$label is required';
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
        prefixIcon: Icon(icon, size: 20, color: Colors.deepPurple.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.red.shade600,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return ScaleTransition(
      scale: _buttonScale,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade500, Colors.deepPurple.shade700],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue to Payment',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<int?> _createOrder(int addressId) async {
    try {
      final orderData = {
        "user_id": userId,
        "address_id": addressId,
        "total": widget.total,
        "items": widget.cartItems
            .map(
              (e) => {
                "product_id": e.productId,
                "qty": e.quantity,
                "price": e.price,
              },
            )
            .toList(),
      };

      log("📦 CREATING ORDER: ${jsonEncode(orderData)}");

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/orders/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(orderData),
      );

      log("⬅️ CREATE ORDER STATUS: ${response.statusCode}");
      log("⬅️ CREATE ORDER RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['order_id'];
      }

      return null;
    } catch (e) {
      log("❌ CREATE ORDER ERROR: $e");
      return null;
    }
  }

  // ✅ CHANGE 2: _handleContinue — PaymentProofScreen navigate karo
  Future<void> _handleContinue() async {
    _buttonController.forward().then((_) => _buttonController.reverse());

    if (userId == null) {
      _showErrorSnackbar('User not logged in');
      return;
    }

    setState(() => _isLoading = true);

    try {
      int? addressId;

      // Saved address use karo
      if (!_showAddNewAddress && _selectedAddressId != null) {
        addressId = _selectedAddressId;
        log("📍 USING SAVED ADDRESS ID: $addressId");
      }
      // New address save karo
      else {
        if (!_formKey.currentState!.validate()) {
          setState(() => _isLoading = false);
          _showErrorSnackbar('Please fill all required fields correctly');
          return;
        }

        final response = await http.post(
          Uri.parse("${ApiService.baseUrl}/api/addresses/save"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "name": _nameController.text.trim(),
            "mobile": _phoneController.text.trim(),
            "address_line": _addressController.text.trim(),
            "city": _cityController.text.trim(),
            "state": _stateController.text.trim(),
            "pincode": _pincodeController.text.trim(),
            "address_type": _selectedAddressType,
          }),
        );

        log("📍 SAVE ADDRESS RESPONSE: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          addressId = data['address_id'] ?? data['id'];
          log("📍 NEW ADDRESS SAVED ID: $addressId");
          await _loadSavedAddresses();
        } else {
          throw Exception("Failed to save address");
        }
      }

      if (addressId == null) throw Exception("No address selected or saved");

      // Order create karo
      final orderId = await _createOrder(addressId);
      if (orderId == null) throw Exception("Failed to create order");

      log("📦 CREATED ORDER ID: $orderId");

      setState(() => _isLoading = false);
      _showSuccessSnackbar('Address confirmed!');

      if (mounted) {
        await context.read<CartProvider>().startPaymentFlow();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // ✅ KEY CHANGE: PaymentProofScreen navigate karo
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentProofScreen(
            orderId: orderId,
            userId: userId!,
            totalAmount: widget.total,
            upiId: 'moradiyahasti@okaxis', // 🔥 TARO UPI ID YAHAN LAKHO
          ),
        ),
      );

      // Return thaya pachhi cart flag handle karo
      if (mounted) {
        final cartProvider = context.read<CartProvider>();
        final paymentInProgress = await cartProvider.isPaymentInProgress;
        if (paymentInProgress) {
          await cartProvider.endPaymentFlow();
          log("🔓 Payment flow ended");
        }
      }
    } catch (e) {
      log("❌ ERROR: $e");
      setState(() => _isLoading = false);

      if (mounted) {
        final cartProvider = context.read<CartProvider>();
        final paymentInProgress = await cartProvider.isPaymentInProgress;
        if (paymentInProgress) await cartProvider.endPaymentFlow();
      }

      _showErrorSnackbar('Failed: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
