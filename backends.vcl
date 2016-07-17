import directors;
 
backend s_xpj_1 {			
  .host = "209.95.60.68";
  .port = "80";
}
backend s_xpj_2 {
  .host = "211.75.1.212";
  .port = "80";
}

backend s_ahui_1 {			
  .host = "209.95.60.68";
  .port = "80";
}
backend s_ahui_2 {
  .host = "211.75.1.212";
  .port = "80";
}
backend s_88net_1 {			
  .host = "209.95.60.68";
  .port = "80";
}
backend s_88net_2 {
  .host = "211.75.1.212";
  .port = "80";
}
backend s_huahua_1 {			
  .host = "209.95.60.68";
  .port = "80";
}
backend s_huahua_2 {
  .host = "211.75.1.212";
  .port = "80";
}
backend s_lpj_1 {			
  .host = "209.95.60.68";
  .port = "80";
}
backend s_lpj_2 {
  .host = "211.75.1.212";
  .port = "80";
}
backend s_cat_1 {			
  .host = "209.95.60.68";
  .port = "80";
}
backend s_cat_2 {
  .host = "211.75.1.212";
  .port = "80";
}
backend s_tiger_1 {			
  .host = "209.95.60.68";
  .port = "80";
}
backend s_tiger_2 {
  .host = "211.75.1.212";
  .port = "80";
}
vcl_init {	# 创建后端主机组，即directors
  new web_xpj = directors.random();
  web_xpj.add_backend(s_xpj_1);
  web_xpj.add_backend(s_xpj_2);
  
  new web_dzyy = directors.random();
  web_dzyy.add_backend(s_ahui_1);
  web_dzyy.add_backend(s_ahui_2);
  
  new web_dzyy = directors.random();
  web_dzyy.add_backend(s_88net_1);
  web_dzyy.add_backend(s_88net_2);
  
  new web_dzyy = directors.random();
  web_dzyy.add_backend(s_huahua_1);
  web_dzyy.add_backend(s_huahua_2);
  
  new web_dzyy = directors.random();
  web_dzyy.add_backend(s_lpj_1);
  web_dzyy.add_backend(s_lpj_2);
  
  new web_dzyy = directors.random();
  web_dzyy.add_backend(s_cat_1);
  web_dzyy.add_backend(s_cat_2);
  
  new web_dzyy = directors.random();
  web_dzyy.add_backend(s_tiger_2);
  web_dzyy.add_backend(s_tiger_2);
}