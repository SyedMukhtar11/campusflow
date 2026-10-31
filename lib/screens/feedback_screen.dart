import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/feedback_entry.dart';
import '../models/program.dart';
import '../providers/auth_provider.dart';
import '../providers/program_provider.dart';
import '../utils/context_colors.dart';


class FeedbackScreen extends StatefulWidget {
  final Program program;
  const FeedbackScreen({super.key, required this.program});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const _categories = [
    'Content',
    'Speaker / Instructor',
    'Venue / Platform',
    'Organisation',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  String? _category;
  bool _ratingError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider?>();
      if (auth?.user?.email != null && _emailCtrl.text.isEmpty) {
        setState(() {
          _emailCtrl.text = auth!.user!.email;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fieldsValid = _formKey.currentState!.validate();
    setState(() => _ratingError = _rating == 0);
    if (!fieldsValid || _rating == 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thank you for your feedback!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.program.title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary)),
              SizedBox(height: 4),
              Text('How was your experience?',
                  style: TextStyle(color: context.textMuted)),
              SizedBox(height: 16),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 38,
                    onPressed: () => setState(() {
                      _rating = i + 1;
                      _ratingError = false;
                    }),
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: filled ? Colors.amber : context.textMuted,
                    ),
                  );
                }),
              ),
              if (_ratingError)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Please select a rating',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'What is this about?'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Please choose a category' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Please enter your email';
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                  return ok ? null : 'Enter a valid email address';
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _commentCtrl,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'Your feedback',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Please enter your feedback';
                  if (value.length < 10) {
                    return 'Please write at least 10 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Submit feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
