import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../domain/models.dart';

/// Reads the course and its lessons from the files shipped with the app.
class ContentRepository {
  ContentRepository({AssetBundle? bundle, this.courseId = 'en'}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String courseId;
  final Map<String, Lesson> _lessons = {};
  Course? _course;

  Future<Course> loadCourse() async {
    final cached = _course;
    if (cached != null) return cached;
    final raw = await _bundle.loadString('assets/content/$courseId/course.json');
    final course = Course.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _course = course;
    return course;
  }

  Future<Lesson> loadLesson(String lessonId) async {
    final cached = _lessons[lessonId];
    if (cached != null) return cached;
    final raw = await _bundle.loadString('assets/content/$courseId/lessons/$lessonId.json');
    final lesson = Lesson.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _lessons[lessonId] = lesson;
    return lesson;
  }
}
