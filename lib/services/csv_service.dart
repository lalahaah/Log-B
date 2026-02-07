import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/partner.dart';

/// CSV 파일 처리 서비스
class CsvService {
  /// 파트너 데이터를 CSV 파일로 다운로드
  static Future<String?> exportPartnersToCsv(List<Partner> partners) async {
    try {
      // CSV 데이터 생성
      final List<List<String>> csvData = [
        Partner.csvHeaders(), // 헤더
        ...partners.map((partner) => partner.toCsvRow()), // 데이터
      ];

      // CSV 문자열 변환
      final String csv = const ListToCsvConverter().convert(csvData);

      // 파일 이름 생성
      final fileName = 'partners_${DateTime.now().millisecondsSinceEpoch}.csv';

      // macOS의 경우 Downloads 폴더 사용
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('다운로드 폴더를 찾을 수 없습니다.');
      }

      final filePath = '${directory.path}/$fileName';

      // 파일 쓰기
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      throw Exception('CSV 내보내기 실패: $e');
    }
  }

  /// CSV 파일에서 파트너 데이터 가져오기
  static Future<List<Partner>> importPartnersFromCsv() async {
    try {
      // 파일 선택
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv'],
          allowMultiple: false,
        );
      } catch (e) {
        throw Exception('파일 선택기 초기화 실패. 앱을 재시작해 보세요. ($e)');
      }

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final file = result.files.first;
      String fileContent;

      if (file.bytes != null) {
        // 웹이나 일부 플랫폼에서 바이트로 직접 읽기
        fileContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        // 경로가 있는 경우 파일 시스템에서 읽기
        final fileHandle = File(file.path!);
        if (!await fileHandle.exists()) {
          throw Exception('선택한 파일을 찾을 수 없습니다.');
        }
        fileContent = await fileHandle.readAsString();
      } else {
        throw Exception('파일 데이터를 읽을 수 없습니다.');
      }

      // CSV 파싱
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        fileContent,
      );

      // 데이터 검증 및 변환
      if (csvData.isEmpty) {
        return [];
      }

      // 첫 번째 행이 헤더인지 확인 (옵션: 실제 데이터와 비교)
      if (csvData.length > 1) {
        csvData.removeAt(0);
      }

      // Partner 객체로 변환
      return csvData.map((row) => Partner.fromCsvRow(row)).toList();
    } catch (e) {
      throw Exception('CSV 가져오기 상세 실패: $e');
    }
  }
}
