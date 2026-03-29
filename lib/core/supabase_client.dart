import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = 'https://cbimymlalisvzbggwumj.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNiaW15bWxhbGlzdnpiZ2d3dW1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1MzQyMzEsImV4cCI6MjA5MDExMDIzMX0.LDB0MboNH-HSm9tjFKdH_Z8KPhehSlS2pQYVPCZcH7g';

  static SupabaseClient get client => Supabase.instance.client;
}
