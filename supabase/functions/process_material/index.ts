import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Tesseract from "npm:tesseract.js@5";
import pdfExtract from "npm:pdf-extraction";
import { Buffer } from "node:buffer";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing Authorization header');

    const supabaseUrl = Deno.env.get('PROJECT_URL') ?? Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseKey = Deno.env.get('PROJECT_ANON_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY') ?? '';

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) throw new Error('Invalid user token');

    const formData = await req.formData();
    const folderName = formData.get('folderName') as string;
    const fileNameRaw = formData.get('fileName') as string;
    const file = formData.get('file') as File;

    if (!folderName || !fileNameRaw || !file) {
      throw new Error('Missing required form fields');
    }

    const fileName = fileNameRaw.replace(/[^a-zA-Z0-9._-]/g, "_");

    if (file.size > 5 * 1024 * 1024) {
      throw new Error("File too large. Max 5MB.");
    }

    const fileType = file.type || "";
    const fileBuffer = new Uint8Array(await file.arrayBuffer());

    let extractedText = "";

    if (fileType.startsWith("image/")) {
      try {
        const result = await Tesseract.recognize(fileBuffer, 'eng');
        extractedText = result?.data?.text || "";
      } catch (err) {
        throw new Error("Image OCR failed: " + err.message);
      }

    } else if (fileType.includes("pdf")) {
      try {
        const nodeBuffer = Buffer.from(fileBuffer);
        const pdfData = await pdfExtract(nodeBuffer);
        extractedText = pdfData.text;

        if (!extractedText.trim()) {
          throw new Error("PDF contains no extractable text. Scanned documents require OCR.");
        }
      } catch (err) {
        throw new Error("PDF parsing failed: " + err.message);
      }

    } else {
      throw new Error("Unsupported file format. Send PNG, JPEG, or PDF.");
    }

    if (!extractedText.trim()) {
      throw new Error("No text could be extracted from file.");
    }

    const filePath = `${user.id}/${folderName}/${fileName}`;

    const { error: uploadError } = await supabase
      .storage
      .from('StudyMaterials')
      .upload(filePath, file, {
        upsert: true,
        contentType: file.type,
      });

    if (uploadError) throw new Error(`Upload failed: ${uploadError.message}`);

    return new Response(
      JSON.stringify({ 
        message: "Extraction successful", 
        path: filePath,
        type: fileType,
        raw_text: extractedText
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  }
});