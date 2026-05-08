import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';

// ─── Subscription tier model ──────────────────────────────────────────────────

enum SubscriptionTier { free, pro, elite }

class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final String price;
  final String period;
  final String badge;
  final Color color;
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.price,
    required this.period,
    required this.badge,
    required this.color,
    required this.features,
    this.isPopular = false,
  });
}

const _plans = [
  SubscriptionPlan(
    tier: SubscriptionTier.free,
    name: 'Free',
    price: '\$0',
    period: 'forever',
    badge: '🌱',
    color: Color(0xFF4CAF50),
    features: [
      'Basic nutrition tracking',
      'Up to 5 recipes saved',
      'Community chat access',
      '3 AI messages/day',
      'Basic progress stats',
    ],
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.pro,
    name: 'Pro',
    price: '\$9.99',
    period: '/month',
    badge: '⚡',
    color: AppColors.primary,
    isPopular: true,
    features: [
      'Everything in Free',
      'Unlimited recipe access',
      'Full AI chatbot access',
      'Meal planning & tracking',
      '1 coach session/month',
      'Advanced analytics',
      'Priority support',
    ],
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.elite,
    name: 'Elite',
    price: '\$24.99',
    period: '/month',
    badge: '👑',
    color: Color(0xFFFF8F00),
    features: [
      'Everything in Pro',
      'Unlimited coach sessions',
      'Doctor consultation access',
      'Personalized meal plans',
      'Custom workout programs',
      'Body scan analysis',
      'Dedicated health manager',
    ],
  ),
];

// ─── Provider ─────────────────────────────────────────────────────────────────

final subscriptionProvider = FutureProvider<SubscriptionTier>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return SubscriptionTier.free;
  final doc = await FirebaseFirestore.instance.collection('subscriptions').doc(user.uid).get();
  if (!doc.exists) return SubscriptionTier.free;
  final tier = doc.data()?['tier'] as String? ?? 'free';
  return SubscriptionTier.values.firstWhere((t) => t.name == tier, orElse: () => SubscriptionTier.free);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class PaywallScreen extends ConsumerStatefulWidget {
  final bool fromFeatureGate;

  const PaywallScreen({super.key, this.fromFeatureGate = false});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  SubscriptionTier _selected = SubscriptionTier.pro;
  bool _isProcessing = false;
  bool _isAnnual = false;

  double get _annualDiscount => 0.3;

  String _adjustedPrice(SubscriptionPlan plan) {
    if (plan.tier == SubscriptionTier.free) return plan.price;
    final base = plan.tier == SubscriptionTier.pro ? 9.99 : 24.99;
    if (_isAnnual) {
      final annual = base * 12 * (1 - _annualDiscount);
      return '\$${annual.toStringAsFixed(0)}';
    }
    return plan.price;
  }

  String _periodLabel(SubscriptionPlan plan) {
    if (plan.tier == SubscriptionTier.free) return plan.period;
    return _isAnnual ? '/year (save 30%)' : plan.period;
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (plan.tier == SubscriptionTier.free) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await FirebaseFirestore.instance.collection('subscriptions').doc(user.uid).set({
        'userId': user.uid,
        'tier': plan.tier.name,
        'plan': plan.name,
        'price': _adjustedPrice(plan),
        'isAnnual': _isAnnual,
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(_isAnnual ? const Duration(days: 365) : const Duration(days: 30)),
        ),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isPremium': plan.tier != SubscriptionTier.free,
        'subscriptionTier': plan.tier.name,
      });

      if (mounted) {
        _showSuccessDialog(plan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(plan.badge, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Welcome to ${plan.name}!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your ${plan.name} subscription is now active. Enjoy all premium features!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: plan.color,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Start Exploring'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTierAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A237E), AppColors.primary, Color(0xFF7B1FA2)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      const Text('✨', style: TextStyle(fontSize: 40))
                          .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 12),
                      Text(
                        'Unlock Your Full Potential',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ).animate().fadeIn(delay: 200.ms),
                      Text(
                        'Choose the plan that fits your goals',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _BillingToggle(isAnnual: _isAnnual, onToggle: (v) => setState(() => _isAnnual = v)),
                  const SizedBox(height: 20),
                  currentTierAsync.when(
                    data: (currentTier) => Column(
                      children: _plans.map((plan) => _PlanCard(
                        plan: plan,
                        isSelected: _selected == plan.tier,
                        isCurrentPlan: currentTier == plan.tier,
                        adjustedPrice: _adjustedPrice(plan),
                        periodLabel: _periodLabel(plan),
                        onTap: () => setState(() => _selected = plan.tier),
                      ).animate().slideX(begin: 0.1, delay: (100 * _plans.indexOf(plan)).ms)).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, st) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  _ComparisonTable(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing ? null : () {
                    final plan = _plans.firstWhere((p) => p.tier == _selected);
                    _subscribe(plan);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _plans.firstWhere((p) => p.tier == _selected).color,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _selected == SubscriptionTier.free ? 'Continue with Free' : 'Subscribe Now',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cancel anytime. No hidden fees. Secure checkout.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Billing Toggle ───────────────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  final bool isAnnual;
  final void Function(bool) onToggle;

  const _BillingToggle({required this.isAnnual, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'Monthly', isSelected: !isAnnual, onTap: () => onToggle(false)),
          _Tab(label: 'Annual  -30%', isSelected: isAnnual, onTap: () => onToggle(true), badgeColor: Colors.green),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? badgeColor;

  const _Tab({required this.label, required this.isSelected, required this.onTap, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isCurrentPlan;
  final String adjustedPrice;
  final String periodLabel;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isCurrentPlan,
    required this.adjustedPrice,
    required this.periodLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? plan.color.withValues(alpha: 0.06) : Colors.white,
          border: Border.all(
            color: isSelected ? plan.color : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [BoxShadow(color: plan.color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(plan.badge, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(plan.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 8),
                            if (plan.isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: plan.color, borderRadius: BorderRadius.circular(10)),
                                child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            if (isCurrentPlan)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                                child: const Text('CURRENT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(adjustedPrice, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: plan.color)),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(periodLabel, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? plan.color : Colors.grey.withValues(alpha: 0.4), width: 2),
                      color: isSelected ? plan.color : Colors.transparent,
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: plan.color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Comparison Table ─────────────────────────────────────────────────────────

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  static const _rows = [
    ['Feature', 'Free', 'Pro', 'Elite'],
    ['Recipes', '5', 'Unlimited', 'Unlimited'],
    ['AI Chat', '3/day', 'Unlimited', 'Unlimited'],
    ['Coach sessions', '0', '1/month', 'Unlimited'],
    ['Doctor access', '✗', '✗', '✓'],
    ['Custom meal plans', '✗', '✓', '✓'],
    ['Analytics', 'Basic', 'Advanced', 'Advanced+'],
    ['Priority support', '✗', '✓', '✓'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Full Comparison', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: _rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              final isHeader = i == 0;
              return TableRow(
                decoration: BoxDecoration(
                  color: isHeader
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : i.isEven ? Colors.grey.withValues(alpha: 0.03) : Colors.white,
                ),
                children: row.asMap().entries.map((cellEntry) {
                  final colIdx = cellEntry.key;
                  final cell = cellEntry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text(
                      cell,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isHeader || colIdx == 0 ? FontWeight.bold : FontWeight.normal,
                        color: cell == '✓' ? Colors.green : cell == '✗' ? Colors.grey[400] : null,
                      ),
                      textAlign: colIdx == 0 ? TextAlign.left : TextAlign.center,
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
