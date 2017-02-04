package com.nldy.uploader;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.io.FileUtils;

/**
 * 文件上传的servlet
 * 
 * @author 弄浪的鱼
 * 
 */
public class UploaderServlet extends HttpServlet {

	private String serverPath = "F:/uploader";

	public void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

	}

	public void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// 1. 创建DiskFileItemFactory对象，配置缓存信息
		DiskFileItemFactory factory = new DiskFileItemFactory();

		// 2. 创建ServletFileUpload对象
		ServletFileUpload sfu = new ServletFileUpload(factory);

		// 3. 设置文件名称的编码
		sfu.setHeaderEncoding("utf-8");

		// 4. 开始解析文件
		String fileMd5 = null;
		// 分块索引 0,1,2,3...
		String chunk = null;
		try {
			List<FileItem> items = sfu.parseRequest(request);

			// 服务器的目录
			String serverPath = "F:/uploader";

			// 5. 获取文件信息
			for (FileItem item : items) {

				// 6. 判断是文件还是普通的数据
				if (item.isFormField()) {
					// 普通数据
					String fileName = item.getFieldName();

					if (fileName.equals("fileMd5")) {
						// 获取文件信息
						fileMd5 = item.getString("utf-8");
						System.out.println(fileMd5);
					}

					if (fileName.equals("chunk")) {
						// 获取文件信息
						chunk = item.getString("utf-8");
						System.out.println(chunk);
					}
				} else {
					// 文件

					// 建立一个临时目录，用于保存所有分块文件
					File chunksDir = new File(serverPath + "/" + fileMd5);
					if (!chunksDir.exists()) {
						chunksDir.mkdir();
					}

					// 保存文件
					File chunkFile = new File(chunksDir + "/" + chunk);

					FileUtils.copyInputStreamToFile(item.getInputStream(),
							chunkFile);
				}
			}
		} catch (FileUploadException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
