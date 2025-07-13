from django.shortcuts import render

# Create your views here.
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from .models import SharedFile

class FileUploadView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        file = request.FILES['file']
        sender = request.POST.get('sender', 'Anonymous')
        shared_file = SharedFile.objects.create(file=file, sender=sender)
        return Response({'file_url': shared_file.file.url})
