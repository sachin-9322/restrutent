import 'package:dio/dio.dart';
import 'package:get/get.dart';

class ServiceDio extends GetxService {
   Future<Dio>createInstances()async{
       Dio dio =  Dio();
       return dio;
   }
}
