<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Java文件上传</title>
<link rel="stylesheet" type="text/css"
	href="${pageContext.request.contextPath}/css/webuploader.css">
<script type="text/javascript"
	src="${pageContext.request.contextPath}/js/jquery-1.7.2.js"> </script>
<script type="text/javascript"
	src="${pageContext.request.contextPath}/js/webuploader.js"> </script>
<style type="text/css">
#dndArea {
	width: 200px;
	height: 100px;
	border-color: black;
	border-style: dashed;
}
</style>
</head>
<body>

	<!-- 上传div -->
	<div id="uploader">

		<!-- 指定文件拖拽区域 -->
		<div id="dndArea">
			<p>将文件拖拽到方框内上传</p>
		</div>

		<!-- 显示文件列表 -->
		<ul id="fileList"></ul>
		<!-- 选择文件区域 -->
		<div id="filePicker">点击上传文件</div>
	</div>

	<script type="text/javascript">
	
		//5.监控文件的三个上传时间点
		//时间点一：所有分块进行上传之前（1.计算文件的MD5 2.判断是否秒传）
		//时间点二：如果分块上传，每个分块上传之前（选文后台该分块是否保存成功）
		//时间点三：分块上传成功（通知后台合并）
		WebUploader,Uploader.register({
			"before-send-file":"beforeSendFile",
			"before-send": "beforeSend",
			"after-send-file": "afterSendFile"
		},{
			//时间点一
			beforeSendFile:function(file){
                //创建一个deffered
                var deferred = WebUploader.Deferred();

                //1.计算文件的唯一标记，用于断点续传和秒传
                (new WebUploader.Uploader()).md5File(file,0,5*1024*1024)
                    .progress(function(percentage){
                        $("#"+file.id).find("div.state").text("正在获取文件信息...");
                    })
                    .then(function(val){
                        fileMd5 = val;

                        $("#"+file.id).find("div.state").text("成功获取文件信息");


                        //2.请求后台是否保存过该文件，如果存在，则跳过该文件，实现秒传功能
                        $.ajax(
                            {
                            type:"POST",
                            url:"${pageContext.request.contextPath}/UploadServlet?action=fileCheck",
                            data:{
                                //文件唯一标记
                                fileMd5:fileMd5
                            },
                            dataType:"json",
                            success:function(response){
                                if(response.ifExist){
                                    $("#"+file.id).find("div.state").text("秒传成功"); 
                                    //如果存在，则跳过该文件，秒传成功
                                    deferred.reject();
                                }else{
                                    //继续上传
                                    deferred.resolve();
                                }
                            }
                            }
                        );

                    });

                //返回deffered
                return deferred.promise();
            },
		
          //时间点2：如果有分块上传，则 每个分块上传之前调用此函数
            //block:代表当前分块对象
            beforeSend:function(block){
                //1.请求后台是否保存过当前分块，如果存在，则跳过该分块文件，实现断点续传功能
                var deferred = WebUploader.Deferred();

                //请求后台是否保存完成该文件信息，如果保存过，则跳过，如果没有，则发送该分块内容
                $.ajax(
                    {
                    type:"POST",
                    url:"${pageContext.request.contextPath}/UploadServlet?action=checkChunk",
                    data:{
                        //文件唯一标记
                        fileMd5:fileMd5,
                        //当前分块下标
                        chunk:block.chunk,
                        //当前分块大小
                        chunkSize:block.end-block.start
                    },
                    dataType:"json",
                    success:function(response){
                        if(response.ifExist){
                            //分块存在，跳过该分块
                            deferred.reject();
                        }else{
                            //分块不存在或者不完整，重新发送该分块内容
                            deferred.resolve();
                        }
                    }
                    }
                );

                //携带当前文件的唯一标记到后台，用于让后台创建保存该文件分块的目录
                this.owner.options.formData.fileMd5 = fileMd5;
                return deferred.promise();          
            },
			
			//时间点三
            afterSendFile:function(file){
                //1.如果分块上传，则通过后台合并所有分块文件

                //请求后台合并文件
                $.ajax(
                    {
                    type:"POST",
                    url:"${pageContext.request.contextPath}/UploadCheckServlet?action=mergeChunks",
                    data:{
                        //文件唯一标记
                        fileMd5:fileMd5,
                        //文件名称
                        fileName:file.name
                    },
                    dataType:"json",
                    success:function(response){
                        alert(response.msg);
                    }
                    }
                );

            },
		});
		
	
		//1.初始化WebUploader，以及配置全局参数
		var uploader = WebUploader.create({

			// swf文件路径
			swf : "${pageContext.request.contextPath}/js/Uploader.swf",

			// 文件接收服务端。
			server : "${pageContext.request.contextPath}/UploaderServlet",

			// 选择文件的按钮。可选。
			// 内部根据当前运行是创建，可能是input元素，也可能是flash.
			pick : '#filePicker',

			// 自动上传
			auto : true,
			//开启脱宅功能，指定拖拽区域
			dnd:"#dndArea",
			//禁止页面其他地方拖拽功能
			disableGlobalDnd:true,
			//开启黏贴功能
			paste:"#uploader"
			
		});
		
		//2. 选择文件后，文件信息队列展示
		//注册fileQueued事件：当文件加入队列后触发
		uploader.on("fileQueued",function(file){
			//追加文件信息div
			$("#fileList").append("<div id='" + file.id + "'class='fileInfo'><img/><span>" + file.name +
					"</span><div class='state'>等待上传...</div><span class='text'><span></div>");
			
			//生成缩略图：调用makeThumb()方法
			//error：制造缩略图失败
			//src:缩略图的路径
			uploader.makeThumb(file,function(error,src){
				var id = $("#" + file.id);
				//如果失败，则显示不能预览
				if(error){
					id.find("img").replaceWith("不能预览");
				}
				
				//成功，则显示缩略图到指定位置
				id.find("img").attr("src",src);
			});
			
		});
		
		//3. 注册上传监听
		//percentage:当前上传进度0-1
		uploader.on("uploadProgress",function(file,percentage){
			var id=$("#"+file.id);
			//更新状态信息
			id.find("div.state").text("上传中...");
			//更新上传的百分比
			id.find("span.text").text(Math.round(percentage*100)+"%");
		});
		
		//4. 注册上传完毕监听
		//response：后台回送数据，json格式
		uploader.on("uploadProgress",function(file,percentage){
			//更新状态信息
			$("#"+file.id).find("div.state").text("上传完毕");
		});
	</script>


</body>
</html>