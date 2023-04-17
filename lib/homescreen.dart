import 'package:flutter/material.dart';
import 'package:my_audio/audio_list_screen.dart';
import 'package:store_redirect/store_redirect.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Uri _url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.tannousapps.quran');
    Uri _url2 = Uri.parse('https://bit.ly/3CGxvON');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("القران الكريم ماهر المعيقلي بدون نت"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap:(){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>AudioListScreen()));
                } ,
                child: Image.asset(
                  
                  'icons/icon.png',
                  height: 300,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)
                )
                ),
                child: const Text(
                  'للاستماع للقران الكريم اضغط هنا',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AudioListScreen()));
                },
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)
                )
                ),

                child: const Text(
                  'الرجاء تقييم التطبيق 5 نجوم بارك الله فيك اضغط هنا',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  StoreRedirect.redirect(androidAppId: 'com.tannousapps.quran');
                },
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)
                )
                ),
                child: const Text(
                  'لتحميل تطبيق الرقية الشرعية بصوت الشيخ نبيل العوضي اضغط هنا',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  StoreRedirect.redirect(
                      androidAppId: 'com.tannousapps.roqya.roqya');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
