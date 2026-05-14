import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PrivateQuestionsScreen extends StatefulWidget {
  final String startupId;

  const PrivateQuestionsScreen({
    super.key,
    required this.startupId,
  });

  @override
  State<PrivateQuestionsScreen> createState() =>
      _PrivateQuestionsScreenState();
}

class _PrivateQuestionsScreenState
    extends State<PrivateQuestionsScreen> {
  final TextEditingController _questionController =
      TextEditingController();

  bool _isPrivate = true;
  bool _isLoading = false;

  Future<void> _sendQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma pergunta'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('createPrivateQuestion');

      await callable.call({
        'startupId': widget.startupId,
        'question': _questionController.text.trim(),
        'privateQuestion': _isPrivate,
      });

      _questionController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pergunta enviada com sucesso!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar pergunta: $e'),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        title: const Text('Perguntas Privadas'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3A1C71),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Envie uma pergunta para a startup',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A1C71),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Perguntas privadas são visíveis apenas para investidores.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _questionController,
              maxLines: 6,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Digite sua pergunta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                value: _isPrivate,
                activeColor: const Color(0xFF6A4CFF),
                title: const Text(
                  'Pergunta privada',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Somente investidores poderão visualizar',
                ),
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A4CFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _sendQuestion,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Enviar pergunta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}